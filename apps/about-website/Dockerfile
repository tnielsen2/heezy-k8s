FROM lscr.io/linuxserver/swag:latest

ARG CF_API_TOKEN

COPY src/ /config/

RUN mkdir -p /config/dns-conf && \
    echo "dns_cloudflare_api_token = ${CF_API_TOKEN}" > /config/dns-conf/cloudflare.ini && \
    chmod 600 /config/dns-conf/cloudflare.ini
