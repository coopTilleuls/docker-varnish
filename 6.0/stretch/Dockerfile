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
# (see persistent deps below)
ENV VMOD_BUILD_DEPS \
		autoconf-archive \
		automake \
		autotools-dev \
		dpkg-dev \
		gcc \
		libtool \
		make \
		pkg-config \
		python-docutils

# persistent / runtime deps
RUN apt-get update && apt-get install -y \
		$VMOD_BUILD_DEPS \
		ca-certificates \
		curl \
		libedit2 \
		libjemalloc1 \
		libncurses5 \
		libpcre3 \
--no-install-recommends && rm -r /var/lib/apt/lists/*

ENV VARNISH_VERSION 6.0.0
ENV VARNISH_URL https://varnish-cache.org/_downloads/varnish-6.0.0.tgz
ENV VARNISH_SHA256 c7b2839c95b2bf1f336abc20b5d8b149c3aa72deff142f2379d1d431206b0bee

RUN set -eux; \
	\
	fetchDeps=' \
		ca-certificates \
		wget \
	'; \
	buildDeps=' \
		libedit-dev \
		libjemalloc-dev \
		libncurses-dev \
		libpcre3-dev \
	'; \
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
CMD ["varnishd"]
