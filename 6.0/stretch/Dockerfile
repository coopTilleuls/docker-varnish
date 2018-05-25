#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM debian:stretch-slim

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r varnish && useradd -r -g varnish varnish

# prevent Debian's Varnish packages from being installed
RUN set -eux; \
	{ \
		echo 'Package: varnish*'; \
		echo 'Pin: release *'; \
		echo 'Pin-Priority: -1'; \
} > /etc/apt/preferences.d/no-debian-varnish

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.10
RUN set -eux; \
	\
	fetchDeps=' \
		ca-certificates \
		wget \
	'; \
	if ! command -v gpg > /dev/null; then \
		fetchDeps="$fetchDeps \
			dirmngr \
			gnupg \
		"; \
	fi; \
	apt-get update; \
	apt-get install -y --no-install-recommends $fetchDeps; \
	rm -rf /var/lib/apt/lists/*; \
	\
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	\
# verify the signature
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	\
	chmod +x /usr/local/bin/gosu; \
# verify that the binary works
	gosu nobody true; \
	\
	apt-get purge -y --auto-remove $fetchDeps

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
	apt-get update; \
	apt-get install -y --no-install-recommends $fetchDeps; \
	rm -rf /var/lib/apt/lists/*; \
	\
	mkdir -p /usr/src; \
	cd /usr/src; \
	\
	wget -O varnish.tar.gz "$VARNISH_URL"; \
	\
	if [ -n "$VARNISH_SHA256" ]; then \
		echo "$VARNISH_SHA256 *varnish.tar.gz" | sha256sum -c -; \
	fi; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $fetchDeps

COPY docker-varnish-source /usr/local/bin/

RUN set -eux; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libedit-dev \
		libjemalloc-dev \
		libncurses-dev \
		libpcre3-dev \
	; \
	rm -rf /var/lib/apt/lists/*; \
	\
	docker-varnish-source extract; \
	cd /usr/src/varnish; \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	./autogen.sh; \
	./configure \
		--build="$gnuArch" \
	; \
	make -j "$(nproc)"; \
	make install; \
	ldconfig; \
	make clean; \
	cd /; \
	docker-varnish-source delete; \
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

EXPOSE 6081
CMD ["varnishd"]
