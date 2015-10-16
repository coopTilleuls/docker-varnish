FROM ubuntu:15.04

ENV DEBIAN_FRONTEND noninteractive

# Update apt sources
#RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list

# Update the package repository
RUN apt-get -qq update

# Install base system
RUN apt-get install -y vim git dpkg-dev curl \
    # Varnish build dependencies.
    automake autotools-dev libedit-dev libjemalloc-dev libncurses-dev libpcre3-dev libtool pkg-config python-docutils python-sphinx graphviz

# Build Varnish from source because that's required to install Varnish modules :D
RUN cd /usr/local/src/ && apt-get source varnish && \
    cd varnish-4.0.2 && \
    sh autogen.sh && \
    sh configure && \
    make && \
    make install

# RUN apt-get install -y build-essential libtool

# Install Querystring Varnish module
RUN cd /usr/local/src/ && \
    git clone https://github.com/Dridi/libvmod-querystring && \
    cd /usr/local/src/libvmod-querystring && \
    ./autogen.sh && \
    ./configure VARNISHSRC=/usr/local/src/varnish-4.0.2 && \
    make  && \
    make install && \
    make check

# Varnish shared library installs to obscure location, so make that available via ldconfig.
# This seems awkward, I wonder if there's a way to stipulate putting this shared object file
# in `/usr/lib/`. Granted I know nothing about UNIX folder layout.
RUN ldconfig && ldconfig -n /usr/local/lib/

# Make our custom VCLs available on the container
ADD default.vcl /etc/varnish/default.vcl

# Export environment variables
ENV VARNISH_PORT 80

# Expose port 80
EXPOSE 80

ADD start /start

RUN chmod 0755 /start

CMD ["/start"]