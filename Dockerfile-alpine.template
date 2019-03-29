FROM alpine:%%ALPINE_VERSION%%

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

ENV VARNISH_VERSION %%VARNISH_VERSION%%
ENV VARNISH_URL %%VARNISH_URL%%
ENV VARNISH_SHA256 %%VARNISH_SHA256%%

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
