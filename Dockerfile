FROM docker.angie.software/angie:minimal

ENV AF_VAULT_DIR="vault"
ENV TZ="Asia/Jerusalem"
ENV AF_USER="admin"
ENV AF_PASS="admin"

COPY theme /etc/angie/theme
COPY run.sh /run.sh

RUN mkdir /data && \
    mkdir -p /etc/angie/conf.d/ && \
    apk add --no-cache gettext tzdata python3 apache2-utils && \
    chmod +x /run.sh

ENTRYPOINT [ "./run.sh" ]
CMD ["angie", "-g", "daemon off;"]