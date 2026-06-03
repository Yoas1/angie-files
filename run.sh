#!/bin/sh



if [ -n "$DIR" ]; then
    cat << 'EOL' > /etc/angie/default.conf.template
server {
  root        /data;
  listen 8080;
  server_name    _;
  location = '/favicon.ico' {
    alias /etc/angie/theme/icon/folder1.png;
    access_log    off;
    log_not_found  off;
  }
  location /theme/  {
    root   /etc/angie;
  }
  autoindex      on;
  autoindex_exact_size   off;
  autoindex_localtime    on;
  add_before_body        "/theme/nginx-before.html";
  add_after_body         "/theme/nginx-after.html";
  location / {
    index       nothing_will_match;
  }
  location ~ "^/upload/(.*)$" {
    set $clean_path $1;
    root     /data;
    rewrite ^/upload/(.*)$ /$1 break;
    auth_basic           "Restricted API - Credentials Required";
    auth_basic_user_file /etc/angie/.htpasswd;
    client_body_temp_path  /tmp/upload_tmp;
    dav_methods  PUT DELETE MKCOL COPY MOVE;
    create_full_put_path   on;
    dav_access             group:rw  all:rw;
    client_max_body_size 10000m;
  }
  location /${DIR}/ {
  #location /yoav/ {
    index       nothing_will_match;
    auth_basic "Restricted Area";
    auth_basic_user_file /etc/angie/.htpasswd;
  
  }
}
EOL

envsubst '${DIR}' < /etc/angie/default.conf.template > /etc/angie/http.d/default.conf
else
        cat << 'EOL' > /etc/angie/http.d/default.conf
server {
  root   /data;
  listen 8080;
  server_name    _;
  location = '/favicon.ico' {
    alias /etc/angie/theme/icon/folder1.png;
    access_log    off;
    log_not_found  off;
  }
  location /theme/  {
    root   /etc/angie;
  }
  autoindex      on;
  autoindex_exact_size   off;
  autoindex_localtime    on;
  add_before_body        "/theme/nginx-before.html";
  add_after_body         "/theme/nginx-after.html";
  location / {
    index       nothing_will_match;
  }
  location ~ "^/upload/(.*)$" {
    set $clean_path $1;
    root     /data;
    rewrite ^/upload/(.*)$ /$1 break;
    auth_basic           "Restricted API - Credentials Required";
    auth_basic_user_file /etc/angie/.htpasswd;
    client_body_temp_path  /tmp/upload_tmp;
    dav_methods  PUT DELETE MKCOL COPY MOVE;
    create_full_put_path   on;
    dav_access             group:rw  all:rw;
    client_max_body_size 10000m;
  }

}
EOL
fi
chmod 777 /etc/angie/conf.d/default.conf
echo "done"


exec "$@"