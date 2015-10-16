FROM buildpack-deps:jessie

RUN \
  useradd -r -s /bin/false varnishd

# Install Varnish dependencies
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    libjemalloc-dev \
    libpcre3-dev \
    python-docutils \
  && rm -rf /var/lib/apt/lists/*

# Install Varnish from source
ENV VARNISH_VERSION=4.1.0
ENV VARNISH_SHA256SUM=4a6ea08e30b62fbf25f884a65f0d8af42e9cc9d25bf70f45ae4417c4f1c99017
RUN \
  mkdir -p /usr/local/src && \
  cd /usr/local/src && \
  curl -sfLO https://repo.varnish-cache.org/source/varnish-$VARNISH_VERSION.tar.gz && \
  echo "${VARNISH_SHA256SUM}  varnish-$VARNISH_VERSION.tar.gz" | sha256sum -c - && \
  tar -xzf varnish-$VARNISH_VERSION.tar.gz && \
  cd varnish-$VARNISH_VERSION && \
  ./autogen.sh && \
  ./configure && \
  make install && \
  rm ../varnish-$VARNISH_VERSION.tar.gz


# Install Querystring Varnish module
ENV QUERYSTRING_VERSION=0.3
RUN \
  cd /usr/local/src/ && \
  curl -sfL https://github.com/Dridi/libvmod-querystring/archive/v$QUERYSTRING_VERSION.tar.gz -o libvmod-querystring-$QUERYSTRING_VERSION.tar.gz && \
  tar -xzf libvmod-querystring-$QUERYSTRING_VERSION.tar.gz && \
  cd libvmod-querystring-$QUERYSTRING_VERSION && \
  ./autogen.sh && \
  make install && \
  rm ../libvmod-querystring-$QUERYSTRING_VERSION.tar.gz

ADD start-varnishd.sh /usr/local/bin/start-varnishd

ENV VARNISH_PORT 80
ENV VARNISH_MEMORY 100m

EXPOSE 80
CMD ["start-varnishd"]

ONBUILD ADD default.vcl /etc/varnish/default.vcl
