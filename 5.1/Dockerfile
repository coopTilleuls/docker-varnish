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

ENV VARNISH_VERSION 5.1.2
ENV VARNISH_FILENAME varnish-5.1.2.tar.gz
ENV VARNISH_SHA256 39d858137e26948a7c85f07363f13f0778da61d234126e03a160a0cb9ba4fce3

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

RUN mkdir /varnishfs \
        && chgrp -R 0 /varnishfs \
        && chmod -R g+rwX /varnishfs

ENV VCL_CONFIG /etc/varnish/default.vcl
ENV VARNISH_MEMORY 100m

EXPOSE 6081
USER 1001

CMD ["start-varnishd"]
