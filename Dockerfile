FROM debian:jessie

# Install base system
RUN apt-get -qq update && \
  apt-get install -y --no-install-recommends \
    automake \
    autotools-dev \
    curl \
    dpkg-dev \
    graphviz \
    libedit-dev \
    libjemalloc-dev \
    libncurses-dev \
    libpcre3-dev \
    libtool \
    pkg-config \
    python-docutils \
    python-sphinx \
    ca-certificates \ 
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
  find /usr/local/man/ -name 'v*' -exec rm {} \;


# Install Querystring Varnish module
ENV QUERYSTRING_VERSION=0.3
RUN \
  cd /usr/local/src/ && \
  curl -sfL https://github.com/Dridi/libvmod-querystring/archive/v$QUERYSTRING_VERSION.tar.gz -o libvmod-querystring-$QUERYSTRING_VERSION.tar.gz && \
  tar -xzf libvmod-querystring-$QUERYSTRING_VERSION.tar.gz && \
  cd libvmod-querystring-$QUERYSTRING_VERSION && \
  ./autogen.sh && \
  ./configure VARNISHSRC=/usr/local/src/varnish-$VARNISH_VERSION && \
  make install && \
  make check && \
  find /usr/local/man/ -name 'v*' -exec rm {} \;

# # Varnish shared library installs to obscure location, so make that available via ldconfig.
# # This seems awkward, I wonder if there's a way to stipulate putting this shared object file
# # in `/usr/lib/`. Granted I know nothing about UNIX folder layout.
# RUN ldconfig && ldconfig -n /usr/local/lib/

# # Make our custom VCLs available on the container
ADD default.vcl /etc/varnish/default.vcl

# # Export environment variables
ENV VARNISH_PORT 80
ENV VARNISH_MEMORY 100m

# # Expose port 80
EXPOSE 80
ADD start /start

RUN chmod 0755 /start

CMD ["/start"]