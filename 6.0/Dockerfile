FROM debian:stretch-slim

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r varnish && useradd -r -g varnish varnish

# grab gosu for easy step-down from root
ENV GOSU_VERSION=1.10
ADD https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64 /usr/local/bin/gosu
ADD https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64.asc /tmp/gosu.asc
# Get GPG Key
RUN set -e; \
	apt-get update -y -qq && apt-get install -y -qq --no-install-recommends gnupg2 dirmngr ca-certificates && rm -rf /var/lib/apt/lists/*; \
	PKG_GPGKEY=B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	found=''; \
	for server in \
		ha.pool.sks-keyservers.net \
		hkp://keyserver.ubuntu.com:80 \
		hkp://p80.pool.sks-keyservers.net:80 \
		pgp.mit.edu \
    ipv4.pool.sks-keyservers.net \
	; do \
		echo "Fetching GPG key $PKG_GPGKEY from $server"; \
    gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$PKG_GPGKEY" && \
    gpg --verify /tmp/gosu.asc /usr/local/bin/gosu && \
    chmod +x /usr/local/bin/gosu && \
    rm /tmp/gosu.asc && \
    gosu nobody true && \
		apt-get purge -y --auto-remove gnupg2 dirmngr ca-certificates && \
    found=yes && break;  \
	done; \
	test -z "$found" && echo >&2 "error: failed to fetch GPG key $PKG_GPGKEY" && exit 1; \
	exit 0

# persistent / runtime deps
ENV RUNTIME_DEPS \
		gcc \
		make \
		autoconf \
		automake \
		dpkg-dev \
		libtool \
		pkg-config \
		python-docutils \
		libedit2 \
		libjemalloc1 \
		libncurses5 \
		libpcre3
RUN apt-get update && apt-get install -y \
		$RUNTIME_DEPS \
	--no-install-recommends && rm -rf /var/lib/apt/lists/*

ENV VARNISH_VERSION 6.0.0
ENV VARNISH_FILENAME varnish-6.0.0.tgz
ENV VARNISH_SHA256 c7b2839c95b2bf1f336abc20b5d8b149c3aa72deff142f2379d1d431206b0bee

RUN set -xe \
	&& BUILD_DEPS=' \
		ca-certificates \
		curl \
		libedit-dev \
		libjemalloc-dev \
		libncurses-dev \
		libpcre3-dev \
	' \
	&& apt-get update && apt-get install -y $BUILD_DEPS --no-install-recommends && rm -rf /var/lib/apt/lists/* \
	&& curl -fSL "http://varnish-cache.org/_downloads/$VARNISH_FILENAME" -o "$VARNISH_FILENAME" \
	&& echo "$VARNISH_SHA256 *$VARNISH_FILENAME" | sha256sum -c - \
	&& mkdir -p /usr/local/src/varnish \
	&& tar -xzf "$VARNISH_FILENAME" -C /usr/local/src/varnish --strip-components=1 \
	&& rm "$VARNISH_FILENAME" \
	&& cd /usr/local/src/varnish \
	&& ./autogen.sh \
	&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& ./configure \
		--build="$gnuArch" \
	&& make -j "$(nproc)" \
	&& make install \
	&& ldconfig \
	&& apt-get purge -y --auto-remove $BUILD_DEPS

RUN mkdir -p /usr/local/var/varnish && chown varnish:varnish /usr/local/var/varnish
VOLUME /usr/local/var/varnish
WORKDIR /usr/local/var/varnish

COPY docker-varnish-entrypoint /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-varnish-entrypoint
ENTRYPOINT ["docker-varnish-entrypoint"]

EXPOSE 6081
CMD ["varnishd"]
