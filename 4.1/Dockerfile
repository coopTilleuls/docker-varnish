FROM debian:jessie

# build deps
RUN \
	apt-get update && apt-get install -y --no-install-recommends \
		automake \
		build-essential \
		libedit-dev \
		libjemalloc-dev \
		libncurses-dev \
		libpcre3-dev \
		libtool \
		pkg-config \
		python-docutils \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# persistent / runtime deps
RUN \
	apt-get update && apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

RUN \
	adduser --quiet --system --no-create-home --group varnish

ENV VARNISH_VERSION 4.1.4
ENV VARNISH_FILENAME varnish-4.1.4.tar.gz
ENV VARNISH_SHA256 44fdeb66fb27af9c18fde6123ef7b0038d6d263c7999a02a780ce4ea1a3965fc

RUN set -xe \
	&& curl -fSL "https://repo.varnish-cache.org/source/$VARNISH_FILENAME" -o "$VARNISH_FILENAME" \
	&& echo "$VARNISH_SHA256 *$VARNISH_FILENAME" | sha256sum -c - \
	&& mkdir -p /usr/local/src \
	&& tar -xzf "$VARNISH_FILENAME" -C /usr/local/src \
	&& mv "/usr/local/src/varnish-$VARNISH_VERSION" /usr/local/src/varnish \
	&& rm "$VARNISH_FILENAME" \
	&& cd /usr/local/src/varnish \
	&& ./autogen.sh \
	&& ./configure \
	&& make install \
	&& ldconfig

COPY start-varnishd.sh /usr/local/bin/start-varnishd

ENV VCL_CONFIG /etc/varnish/default.vcl
ENV VARNISH_MEMORY 100m

EXPOSE 6081

CMD ["start-varnishd"]
