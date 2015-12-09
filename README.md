# Varnish

## Supported tags and respective `Dockerfile` links

-	[`4.1.0`, `4.1`, `4`, `latest` (*4.1.0/Dockerfile*)](https://github.com/newsdev/docker-varnish/blob/4/Dockerfile)

## What is Varnish?

[Varnish Cache](https://www.varnish-cache.org/) is a web application accelerator also known as a caching HTTP reverse proxy. You install it in front of any server that speaks HTTP and configure it to cache the contents. Varnish Cache is really, really fast. It typically speeds up delivery with a factor of 300 - 1000x, depending on your architecture.

> [wikipedia.org/wiki/Varnish_(software)](https://en.wikipedia.org/wiki/Varnish_(software))

## How to use this image.

This image is intended as a base image for other images to built on.

### Create a `Dockerfile` in your Varnish project

```dockerfile
FROM newsdev/varnish:4.1.0
```

### Create a `default.vcl` in your Varnish project

e.g.

```vcl
vcl 4.0;

backend default {
    .host = "www.nytimes.com";
    .port = "80";
}
```

Then, run the commands to build and run the Docker image:

```console
$ docker build -t my-varnish .
$ docker run -it --rm --name my-running-varnish my-varnish
```

### Customize configuration

You can override the port Varnish serves in your Dockerfile.

```dockerfile
FROM newsdev/varnish:4.1.0

ENV VARNISH_PORT 8080
EXPOSE 8080
```

You can override the size of the cache.

```dockerfile
FROM newsdev/varnish:4.1.0

ENV VARNISH_MEMORY 1G
```

## How to install VMODs (Varnish Modules)

[Varnish Modules](https://www.varnish-cache.org/vmods) are extensions written for Varnish Cache.

To install Varnish Modules, you will need the Varnish source to compile against. This is why we install Varnish from source in this image rather than using a package manager.

Install VMODs in your Varnish project's Dockerfile. For example, to install the Querystring module:

```dockerfile
FROM newsdev/varnish:4.1.0

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
  rm -r ../libvmod-querystring-$QUERYSTRING_VERSION*
```

# License

View [license information](https://www.apache.org/licenses/LICENSE-2.0) for the software contained in this image.

# Supported Docker versions

This image is supported on Docker version 1.9.1.

Support for older versions (down to 1.6) is provided on a best-effort basis.

Please see [the Docker installation documentation](https://docs.docker.com/installation/) for details on how to upgrade your Docker daemon.

## Issues

If you have any problems with or questions about this image, please contact us through a [GitHub issue](https://github.com/newsdev/docker-varnish/issues).

## Contributing

You are invited to contribute new features, fixes, or updates, large or small; we are always thrilled to receive pull requests, and do our best to process them as fast as we can.

Before you start to code, we recommend discussing your plans through a [GitHub issue](https://github.com/docker-library/php/issues), especially for more ambitious contributions. This gives other contributors a chance to point you in the right direction, give you feedback on your design, and help you find out if someone else is working on the same thing.