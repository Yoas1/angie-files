FROM docker.angie.software/angie:minimal

ENV DIR="vault"

#COPY default.conf /etc/angie/conf.d/
COPY theme /etc/angie/theme
COPY run.sh /run.sh

RUN mkdir /data && \
    mkdir -p /etc/angie/conf.d/ && \
    apk add --no-cache gettext && \
    chmod +x /run.sh

ENTRYPOINT [ "./run.sh" ]
CMD ["angie", "-g", "daemon off;"]

# docker run -it --rm -v ./data:/data -p 8080:8080 -v ./.htpasswd:/etc/angie/.htpasswd -e DIR=yoas1 angie-files:1.0
# docker run -it --rm -v ./data:/data -p 8080:8080 -v ./.htpasswd:/etc/angie/.htpasswd angie-files:1.0
# docker run -it --rm -v ./data:/data -p 8080:8080 angie-files:1.0

# curl -u <user>:<password> -T run.sh http://127.0.0.1:8080/upload/yoas1/run.sh
# curl -u <user>:<password> -X DELETE http://127.0.0.1:8080/upload/yoas1/run.sh
# curl -u <user>:<password> -X DELETE -H "Depth: infinity" http://127.0.0.1:8080/upload/yoas1/test/