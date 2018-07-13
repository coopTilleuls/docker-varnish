# Supported tags and respective `Dockerfile` links

- [`6.0.0-stretch`, `6.0-stretch`, `6-stretch`, `6.0.0`, `6.0`, `6`, `latest` (*6.0/stretch/Dockerfile*)](https://github.com/coopTilleuls/docker-varnish/blob/master/6.0/stretch/Dockerfile)
- [`4.1.10-stretch`, `4.1-stretch`, `4-stretch`, `4.1.10`, `4.1`, `4` (*4.1/stretch/Dockerfile*)](https://github.com/coopTilleuls/docker-varnish/blob/master/4.1/stretch/Dockerfile)

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
$ docker run --name my-running-varnish -v /path/to/default.vcl:/usr/local/etc/varnish/default.vcl:ro --tmpfs /usr/local/var/varnish:exec -d cooptilleuls/varnish
```

Alternatively, a simple `Dockerfile` can be used to generate a new image that includes the necessary `default.vcl` (which is a much cleaner solution than the bind mount above):

```dockerfile
FROM cooptilleuls/varnish:6.0

COPY default.vcl /usr/local/etc/varnish/
```

Place this file in the same directory as your `default.vcl`, run `docker build -t my-varnish .`, then start your container:

```console
$ docker run --name my-running-varnish --tmpfs /usr/local/var/varnish:exec -d my-varnish
```

### Exposing the port

```console
$ docker run --name my-running-varnish --tmpfs /usr/local/var/varnish:exec -d -p 8080:80 my-varnish
```

Then you can hit `http://localhost:8080` or `http://host-ip:8080` in your browser.

## Advanced configuration using environment variables

You can override the size of the cache:

```console
$ docker run --name my-running-varnish -e "VARNISH_MEMORY=1G" --tmpfs /usr/local/var/varnish:exec -d my-varnish
```

You can pass additional parameters to the `varnishd` process:

```console
$ docker run --name my-running-varnish -e "VARNISH_DAEMON_OPTS=-t 3600 -p http_req_hdr_len=16384 -p http_resp_hdr_len=16384" --tmpfs /usr/local/var/varnish:exec -d my-varnish
```

You can change the path of the VCL configuration file:

```console
$ docker run --name my-running-varnish -e "VARNISH_VCL=/root/custom.vcl" -v /path/to/custom.vcl:/root/custom.vcl:ro --tmpfs /usr/local/var/varnish:exec -d my-varnish
```

You can also change the ports used in a `Dockerfile`.

```
FROM cooptilleuls/varnish:6.0

ENV VARNISH_LISTEN 8080
ENV VARNISH_DAEMON_OPTS "additional varnish options here"
EXPOSE 8080
```

Or with a command:

```console
$ docker run --name my-running-varnish -e "VARNISH_LISTEN=8080" --tmpfs /usr/local/var/varnish:exec -d -p 8080:8080 my-varnish
```

# How to install VMODs (Varnish Modules)

[Varnish Modules](https://www.varnish-cache.org/vmods) are extensions written for Varnish Cache.

To install Varnish Modules, you will need the Varnish source to compile against. This is why we install Varnish from source in this image rather than using a package manager.

Install VMODs in your Varnish project's `Dockerfile`. For example, to install the Querystring module:

```dockerfile
FROM cooptilleuls/varnish:6.0

# install vmod-querystring
ENV VMOD_QUERYSTRING_VERSION 1.0.5
RUN set -eux; \
	\
	fetchDeps=' \
		ca-certificates \
		wget \
	'; \
	apt-get update; \
	apt-get install -y --no-install-recommends $fetchDeps; \
	rm -rf /var/lib/apt/lists/*; \
	\
	wget -O vmod-querystring.tar.gz "https://github.com/Dridi/libvmod-querystring/releases/download/v$VMOD_QUERYSTRING_VERSION/vmod-querystring-$VMOD_QUERYSTRING_VERSION.tar.gz"; \
	mkdir -p /usr/local/src/vmod-querystring; \
	tar -zxf vmod-querystring.tar.gz -C /usr/local/src/vmod-querystring --strip-components=1; \
	rm vmod-querystring.tar.gz; \
	\
	cd /usr/local/src/vmod-querystring; \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	./configure \
		--build="$gnuArch" \
	; \
	make -j "$(nproc)"; \
	make install; \
	\
	cd /; \
	rm -rf /usr/local/src/vmod-querystring; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $fetchDeps
```

# License

View [license information](https://github.com/varnishcache/varnish-cache/blob/master/LICENSE) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
