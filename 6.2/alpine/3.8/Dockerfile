#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM alpine:3.8

RUN apk add git alpine-sdk && \
	    adduser -D builder && \
	    addgroup builder abuild && \
	    chgrp abuild /var/cache/distfiles && \
	    su builder -c "abuild-keygen -na" && \
	    chmod g+w /var/cache/distfiles && \
	    su builder -c "git clone https://git.alpinelinux.org/aports /tmp/aports" && \
	    cd /tmp/aports/main/varnish && \
	    su builder -c "abuild checksum && abuild -r" && \
	    apk add ~builder/packages/main/x86_64/*.apk --allow-untrusted

WORKDIR /usr/local/var/varnish
RUN chown -R varnish:varnish /usr/local/var/varnish
VOLUME /usr/local/var/varnish

COPY docker-varnish-entrypoint /usr/local/bin/
ENTRYPOINT ["docker-varnish-entrypoint"]

EXPOSE 80
CMD ["varnishd", "-F", "-f", "/usr/local/etc/varnish/default.vcl"]
