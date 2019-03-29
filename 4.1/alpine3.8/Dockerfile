#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM alpine:3.8

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN set -eux; \
	addgroup -S varnish; \
	for user in varnish vcache; do \
		adduser -S -G varnish $user; \
	done

# dependencies required for building VMOD (Varnish modules)
ENV VMOD_BUILD_DEPS \
		autoconf \
		# autoconf-archive \
		automake \
		libtool \
		make \
		pkgconf \
		python3

# persistent / runtime deps
RUN apk add --no-cache --virtual .persistent-deps \
		gcc \
		libc-dev \
		libgcc

ENV VARNISH_VERSION 4.1.11
ENV VARNISH_URL https://varnish-cache.org/_downloads/varnish-4.1.11.tgz
ENV VARNISH_SHA256 f937a45116f3a7fbb38b2b5d7137658a4846409630bb9eccdbbb240e1a1379bc

COPY *.patch /varnish-alpine-patches/

RUN set -eux; \
	\
	fetchDeps=' \
		ca-certificates \
		wget \
	'; \
	buildDeps=" \
		$VMOD_BUILD_DEPS \
		coreutils \
		dpkg \
		dpkg-dev \
		libedit-dev \
		libexecinfo-dev \
		linux-headers \
		ncurses-dev \
		patch \
		pcre-dev \
	"; \
	apk add --no-cache --virtual .build-deps $fetchDeps $buildDeps; \
	\
	wget -O varnish.tar.gz "$VARNISH_URL"; \
	\
	if [ -n "$VARNISH_SHA256" ]; then \
		echo "$VARNISH_SHA256 *varnish.tar.gz" | sha256sum -c -; \
	fi; \
	\
	mkdir -p /usr/src/varnish; \
	tar -zxf varnish.tar.gz -C /usr/src/varnish --strip-components=1; \
	rm varnish.tar.gz; \
	\
	cd /usr/src/varnish; \
	for p in /varnish-alpine-patches/*.patch; do \
		[ -f "$p" ] || continue; \
		patch -p1 -i "$p"; \
	done; \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	./autogen.sh; \
	./configure \
		--build="$gnuArch" \
		--without-jemalloc \
		--with-rst2man=$(command -v true) \
		--with-sphinx-build=$(command -v true) \
	; \
	make -j "$(nproc)"; \
	make install; \
	\
	cd /; \
	rm -r /usr/src/varnish; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ] || [ -e /usr/local/lib/varnish/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-cache --virtual .varnish-rundeps $runDeps; \
	\
	apk del .build-deps; \
	\
	varnishd -V

WORKDIR /usr/local/var/varnish
RUN chown -R varnish:varnish /usr/local/var/varnish
VOLUME /usr/local/var/varnish

COPY docker-varnish-entrypoint /usr/local/bin/
ENTRYPOINT ["docker-varnish-entrypoint"]

EXPOSE 80
CMD ["varnishd", "-F", "-f", "/usr/local/etc/varnish/default.vcl"]
