#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM debian:stretch-slim

RUN apt-get update && \
    apt-get install -y curl && \
    curl -s https://packagecloud.io/install/repositories/varnishcache/varnish60lts/script.deb.sh |  bash && \
    apt-get update && \
    apt-get install -y varnish && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /etc/varnish

COPY docker-varnish-entrypoint /usr/local/bin/
ENTRYPOINT ["docker-varnish-entrypoint"]

EXPOSE 80
CMD ["varnishd", "-F", "-f", "/etc/varnish/default.vcl"]
