# Supported tags and respective `Dockerfile` links

-	[`4.1.3`, `4.1`, `4`, `latest` (*4.1/Dockerfile*)](https://github.com/tripviss/docker-varnish/blob/master/4.1/Dockerfile)

# What is Varnish?

[Varnish Cache](https://www.varnish-cache.org/) is a web application accelerator also known as a caching HTTP reverse proxy. You install it in front of any server that speaks HTTP and configure it to cache the contents. Varnish Cache is really, really fast. It typically speeds up delivery with a factor of 300 - 1000x, depending on your architecture.

> [wikipedia.org/wiki/Varnish_(software)](https://en.wikipedia.org/wiki/Varnish_(software))

# How to use this image.

## Basic usage

Create a `default.vcl` file:

```vcl
vcl 4.0;

backend default {
    .host = "www.nytimes.com";
    .port = "80";
}
```

Then run:

```console
$ docker run --name my-running-varnish -v /path/to/default.vcl:/etc/varnish/default.vcl:ro -d tripviss/varnish
```

Alternatively, a simple `Dockerfile` can be used to generate a new image that includes the necessary `default.vcl` (which is a much cleaner solution than the bind mount above):

```dockerfile
FROM tripviss/varnish

COPY default.vcl /etc/varnish/
```

Place this file in the same directory as your `default.vcl`, run `docker build -t my-varnish .`, then start your container:

```console
$ docker run --name my-running-varnish -d my-varnish
```

### Exposing the port

```console
$ docker run --name my-running-varnish -d -p 8080:6081 my-varnish
```

Then you can hit `http://localhost:8080` or `http://host-ip:8080` in your browser.

## Advanced configuration using environment variables

You can override the size of the cache:

```console
$ docker run --name my-running-varnish -e "VARNISH_MEMORY=1G" -d my-varnish
```

You can pass additional parameters to the `varnishd` process:

```console
$ docker run --name my-running-varnish -e "VARNISHD_PARAMS=-t 3600 -p http_req_hdr_len=16384 -p http_resp_hdr_len=16384" -d my-varnish
```

You can change the path of the VCL configuration file:

```console
$ docker run --name my-running-varnish -e "VCL_CONFIG=/root/custom.vcl" -v /path/to/custom.vcl:/root/custom.vcl:ro -d my-varnish
```

# How to install VMODs (Varnish Modules)

[Varnish Modules](https://www.varnish-cache.org/vmods) are extensions written for Varnish Cache.

To install Varnish Modules, you will need the Varnish source to compile against. This is why we install Varnish from source in this image rather than using a package manager.

Install VMODs in your Varnish project's Dockerfile. For example, to install the Querystring module:

```dockerfile
FROM tripviss/varnish:4.1

# Install Querystring Varnish module
ENV QUERYSTRING_VERSION 0.3
ENV QUERYSTRING_FILENAME libvmod-querystring-0.3.tar.gz
RUN \
  curl -fSL "https://github.com/Dridi/libvmod-querystring/archive/v$QUERYSTRING_VERSION.tar.gz" -o "$QUERYSTRING_FILENAME" \
  && tar -xzf "$QUERYSTRING_FILENAME" -C /usr/local/src \
  && mv "/usr/local/src/libvmod-querystring-$QUERYSTRING_VERSION" /usr/local/src/libvmod-querystring \
  && rm "$QUERYSTRING_FILENAME" \
  && cd /usr/local/src/libvmod-querystring \
  && ./autogen.sh \
  && ./configure VARNISHSRC=/usr/local/src/varnish \
  && make install
```

# License

View [license information](https://github.com/varnishcache/varnish-cache/blob/master/LICENSE) for the software contained in this image.

# Supported Docker versions

This image is supported on Docker version 1.11.2.

Support for older versions (down to 1.6) is provided on a best-effort basis.

Please see [the Docker installation documentation](https://docs.docker.com/installation/) for details on how to upgrade your Docker daemon.

# User Feedback

## Issues

If you have any problems with or questions about this image, please contact us through a [GitHub issue](https://github.com/tripviss/docker-varnish/issues).

## Contributing

You are invited to contribute new features, fixes, or updates, large or small; we are always thrilled to receive pull requests, and do our best to process them as fast as we can.

Before you start to code, we recommend discussing your plans through a [GitHub issue](https://github.com/tripviss/docker-varnish/issues), especially for more ambitious contributions. This gives other contributors a chance to point you in the right direction, give you feedback on your design, and help you find out if someone else is working on the same thing.