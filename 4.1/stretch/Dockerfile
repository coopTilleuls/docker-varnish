#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM debian:stretch-slim

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN set -eux; \
	groupadd -r varnish; \
	for user in varnish vcache; do \
		useradd -r -g varnish $user; \
	done

# prevent Debian's Varnish packages from being installed
RUN set -eux; \
	{ \
		echo 'Package: varnish*'; \
		echo 'Pin: release *'; \
		echo 'Pin-Priority: -1'; \
	} > /etc/apt/preferences.d/no-debian-varnish

# dependencies required for building VMOD (Varnish modules)
ENV VMOD_BUILD_DEPS \
		autoconf-archive \
		automake \
		autotools-dev \
		libtool \
		make \
		pkg-config \
		python3

# persistent / runtime deps
RUN apt-get update && apt-get install -y \
		gcc \
		libc6-dev \
	--no-install-recommends && rm -r /var/lib/apt/lists/*

ENV VARNISH_VERSION 4.1.11
ENV VARNISH_URL https://varnish-cache.org/_downloads/varnish-4.1.11.tgz
ENV VARNISH_SHA256 f937a45116f3a7fbb38b2b5d7137658a4846409630bb9eccdbbb240e1a1379bc

RUN set -eux; \
	\
	fetchDeps=' \
		ca-certificates \
		wget \
	'; \
	buildDeps=" \
		$VMOD_BUILD_DEPS \
		dpkg-dev \
		libedit-dev \
		libjemalloc-dev \
		libncurses5-dev \
		libpcre3-dev \
	"; \
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends $fetchDeps $buildDeps; \
	rm -rf /var/lib/apt/lists/*; \
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
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	./autogen.sh; \
	./configure \
		--build="$gnuArch" \
		--with-rst2man=$(command -v true) \
		--with-sphinx-build=$(command -v true) \
	; \
	make -j "$(nproc)"; \
	make install; \
	ldconfig; \
	\
	cd /; \
	rm -r /usr/src/varnish; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
	find /usr/local -type f -executable -exec ldd '{}' ';' \
		| awk '/=>/ { print $(NF-1) }' \
		| sort -u \
		| xargs -r dpkg-query --search \
		| cut -d: -f1 \
		| sort -u \
		| xargs -r apt-mark manual \
	; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	\
	varnishd -V

WORKDIR /usr/local/var/varnish
RUN chown -R varnish:varnish /usr/local/var/varnish
VOLUME /usr/local/var/varnish

COPY docker-varnish-entrypoint /usr/local/bin/
ENTRYPOINT ["docker-varnish-entrypoint"]

EXPOSE 80
CMD ["varnishd", "-F", "-f", "/usr/local/etc/varnish/default.vcl"]
