FROM debian:jessie

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r varnish && useradd -r -g varnish varnish

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
	&& apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true \
	&& apt-get purge -y --auto-remove ca-certificates wget

# persistent / runtime deps
ENV VMOD_BUILD_DEPS \
		autoconf \
		automake \
		dpkg-dev \
		gcc \
		libtool \
		make \
		pkg-config \
		python-docutils
RUN apt-get update && apt-get install -y \
		$VMOD_BUILD_DEPS \
		ca-certificates \
		curl \
		libedit2 \
		libjemalloc1 \
		libncurses5 \
		libpcre3 \
	--no-install-recommends && rm -rf /var/lib/apt/lists/*

ENV VARNISH_VERSION 4.1.6
ENV VARNISH_FILENAME varnish-4.1.6.tgz
ENV VARNISH_SHA256 c7ac460b521bebf772868b2f5aefc2f2508a1e133809cd52d3ba1b312226e849

RUN set -xe \
	&& buildDeps=' \
		libedit-dev \
		libjemalloc-dev \
		libncurses-dev \
		libpcre3-dev \
	' \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/* \
	&& curl -fSL "https://varnish-cache.org/_downloads/$VARNISH_FILENAME" -o "$VARNISH_FILENAME" \
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
	&& apt-get purge -y --auto-remove $buildDeps

RUN mkdir -p /usr/local/var/varnish && chown varnish:varnish /usr/local/var/varnish
VOLUME /usr/local/var/varnish
WORKDIR /usr/local/var/varnish

COPY docker-varnish-entrypoint /usr/local/bin/

ENTRYPOINT ["docker-varnish-entrypoint"]

EXPOSE 6081
CMD ["varnishd"]
