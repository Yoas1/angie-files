#!/bin/sh

FILE="/etc/angie/pass/.htpasswd"

# On first start, env vars USER / PASS can override.
# If user mounts their own .htpasswd, the marker file is absent, so no override.
if [ ! -f "$FILE" ]; then
    # No htpasswd at all (fresh state without build defaults) - generate one
    mkdir -p /etc/angie/pass
    USER="${USER:-admin}"
    PASS="${PASS:-admin}"
    htpasswd -bc "$FILE" "$USER" "$PASS"
fi

# Always start password change API server (used only when auth is configured)
python3 /etc/angie/theme/admin-dashboard/change-password.py &

if [ -f "$FILE" ]; then
    cat << 'EOF' > /etc/angie/default.conf.template
server {
  root        /data;
  listen 8080;
  server_name    _;
  location = '/favicon.ico' { alias /etc/angie/theme/icon/folder1.png; access_log off; log_not_found off; }
  location /theme/  { root   /etc/angie; }
  autoindex      on;
  autoindex_exact_size   off;
  autoindex_localtime    on;
  add_before_body        "/theme/nginx-before.html";
  add_after_body         "/theme/nginx-after.html";
  location / { index nothing_will_match; }
  
  # Auth/Routing Refactor
  location /api/auth {
    auth_basic "Admin API"; auth_basic_user_file /etc/angie/pass/.htpasswd;
    add_header 'Access-Control-Allow-Origin' '$http_origin' always;
    add_header 'Access-Control-Allow-Credentials' 'true' always;
    return 204;
  }
  location /api/change-password {
    proxy_pass http://127.0.0.1:9090;
    proxy_set_header Host $host;
  }
  location /-/dashboard {
    rewrite ^ /admin-dashboard/index.html break;
    root /etc/angie/theme;
    default_type text/html; autoindex off; add_before_body ""; add_after_body "";
    add_header X-Locked-Directory "/${DIR}/";
  }
  location /login {
    rewrite ^ /admin-dashboard/login.html break;
    root /etc/angie/theme;
    default_type text/html; autoindex off; add_before_body ""; add_after_body "";
  }
  location ~ "^/upload/(.*)$" {
    root /data; rewrite ^/upload/(.*)$ /$1 break;
    dav_methods PUT DELETE MKCOL COPY MOVE; create_full_put_path on; dav_access group:rw all:rw; client_max_body_size 10000m;
    add_header 'Access-Control-Allow-Origin' '$http_origin' always;
    add_header 'Access-Control-Allow-Credentials' 'true' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE, MKCOL' always;
    if ($request_method = 'OPTIONS') { add_header 'Access-Control-Allow-Headers' 'Authorization,Content-Type,Range'; return 204; }
  }
  location /${DIR}/ { index nothing_will_match; auth_basic "Restricted Area"; auth_basic_user_file /etc/angie/pass/.htpasswd; error_page 401 /theme/401.html; }
}
EOF
envsubst '${DIR}' < /etc/angie/default.conf.template > /etc/angie/http.d/default.conf
fi
chmod -R 777 /data
echo "done"
exec "$@"
