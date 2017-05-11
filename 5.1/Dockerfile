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

ENV VARNISH_VERSION 5.1.2
ENV VARNISH_FILENAME varnish-5.1.2.tar.gz
ENV VARNISH_SHA256 39d858137e26948a7c85f07363f13f0778da61d234126e03a160a0cb9ba4fce3

RUN set -xe \
	&& buildDeps=' \
		libedit-dev \
		libjemalloc-dev \
		libncurses-dev \
		libpcre3-dev \
	' \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/* \
	&& curl -fSL "https://repo.varnish-cache.org/source/$VARNISH_FILENAME" -o "$VARNISH_FILENAME" \
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

COPY start-varnishd.sh /usr/local/bin/start-varnishd

ENV VCL_CONFIG /etc/varnish/default.vcl
ENV VARNISH_MEMORY 100m

EXPOSE 6081

CMD ["start-varnishd"]
