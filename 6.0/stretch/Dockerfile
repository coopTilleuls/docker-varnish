#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM debian:stretch-slim

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN set -eux; \
	groupadd -r varnish; \
	for user in varnish vcache; do \
		useradd -r -g varnish $user; \
	done

# dependencies required for building VMODs (Varnish modules)
ENV VMOD_BUILD_DEPS \
		autoconf-archive \
		automake \
		autotools-dev \
		libtool \
		make \
		pkg-config \
		python3

# persistent / runtime deps
RUN apt-get update && apt-get install -y \
		apt-transport-https \
		ca-certificates \
	--no-install-recommends && rm -r /var/lib/apt/lists/*

RUN set -eux; \
	\
	fetchDeps=' \
		wget \
	'; \
	if ! command -v gpg > /dev/null; then \
		fetchDeps="$fetchDeps \
			dirmngr \
			gnupg \
		"; \
	fi; \
	apt-get update; \
	apt-get install -y --no-install-recommends $fetchDeps; \
	rm -rf /var/lib/apt/lists/*; \
	\
	export GNUPGHOME="$(mktemp -d)"; \
# key is not found on any keyserver, but we match its fingerprint
	wget -O - 'https://packagecloud.io/varnishcache/varnish60lts/gpgkey' | gpg --batch --import; \
	gpg --batch --export 'DD2C378724BD39C18AAA47FE3AEAFFBB82FBBA5F' > /etc/apt/trusted.gpg.d/varnish.gpg; \
	command -v gpgconf > /dev/null && gpgconf --kill all; \
	rm -rf "$GNUPGHOME"; \
	apt-key list; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $fetchDeps

ENV VARNISH_PACKAGE_VERSION 6.0.2-1~stretch

RUN set -eux; \
	\
# see note below about "*.pyc" files
	export PYTHONDONTWRITEBYTECODE=1; \
	\
	dpkgArch="$(dpkg --print-architecture)"; \
	case "$dpkgArch" in \
		amd64) \
# arches officialy built by upstream
			echo "deb https://packagecloud.io/varnishcache/varnish60lts/debian/ stretch main" > /etc/apt/sources.list.d/varnish.list; \
			apt-get update; \
			;; \
		*) \
# we're on an architecture upstream doesn't officially build for
# let's build binaries from their published source packages
			echo "deb-src https://packagecloud.io/varnishcache/varnish60lts/debian/ stretch main" > /etc/apt/sources.list.d/varnish.list; \
			\
			tempDir="$(mktemp -d)"; \
			cd "$tempDir"; \
			\
			savedAptMark="$(apt-mark showmanual)"; \
			\
# build .deb files from upstream's source packages (which are verified by apt-get)
			apt-get update; \
			apt-get build-dep -y \
				"varnish=$VARNISH_PACKAGE_VERSION" \
			; \
			DEB_BUILD_OPTIONS="nocheck parallel=$(nproc)" \
				apt-get source --compile \
					"varnish=$VARNISH_PACKAGE_VERSION" \
			; \
# we don't remove APT lists here because they get re-downloaded and removed later
			\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
# (which is done after we install the built packages so we don't have to redownload any overlapping dependencies)
			apt-mark showmanual | xargs apt-mark auto > /dev/null; \
			apt-mark manual $savedAptMark; \
			\
# create a temporary local APT repo to install from (so that dependency resolution can be handled by APT, as it should be)
			ls -lAFh; \
			dpkg-scanpackages . > Packages; \
			grep '^Package: ' Packages; \
			echo "deb [ trusted=yes ] file://$tempDir ./" > /etc/apt/sources.list.d/temp.list; \
# work around the following APT issue by using "Acquire::GzipIndexes=false" (overriding "/etc/apt/apt.conf.d/docker-gzip-indexes")
#   Could not open file /var/lib/apt/lists/partial/_tmp_tmp.ODWljpQfkE_._Packages - open (13: Permission denied)
#   ...
#   E: Failed to fetch store:/var/lib/apt/lists/partial/_tmp_tmp.ODWljpQfkE_._Packages  Could not open file /var/lib/apt/lists/partial/_tmp_tmp.ODWljpQfkE_._Packages - open (13: Permission denied)
			apt-get -o Acquire::GzipIndexes=false update; \
			;; \
	esac; \
	\
	apt-get install -y \
		"varnish=$VARNISH_PACKAGE_VERSION" \
	; \
	\
	rm -rf /var/lib/apt/lists/*; \
	\
	if [ -n "${tempDir:-}" ]; then \
# if we have leftovers from building, let's purge them (including extra, unnecessary build deps)
		apt-get purge -y --auto-remove; \
		rm -rf "$tempDir" /etc/apt/sources.list.d/temp.list; \
	fi; \
	\
# some of the steps above generate a lot of "*.pyc" files (and setting "PYTHONDONTWRITEBYTECODE" beforehand doesn't propagate properly for some reason), so we clean them up manually (as long as they aren't owned by a package)
	find /usr -name '*.pyc' -type f -exec bash -c 'for pyc; do dpkg -S "$pyc" &> /dev/null || rm -vf "$pyc"; done' -- '{}' +

WORKDIR /var/lib/varnish
VOLUME /var/lib/varnish

COPY docker-varnish-entrypoint /usr/local/bin/
ENTRYPOINT ["docker-varnish-entrypoint"]

EXPOSE 80
CMD ["varnishd", "-F", "-f", "/etc/varnish/default.vcl"]
