#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

generated_warning() {
	cat <<-EOH
		#
		# NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
		#
		# PLEASE DO NOT EDIT IT DIRECTLY.
		#

	EOH
}

travisEnv=
for version in "${versions[@]}"; do
	possibles=( $(
		{
			git ls-remote --tags https://github.com/varnishcache/varnish-cache.git "refs/tags/varnish-${version}.*" \
				| sed -r 's!^.*refs/tags/varnish-([0-9a-z.]+).*$!\1!' \
			|| :
		} | sort -ruV
	) )

	fullVersion=
	if [ "${#possibles[@]}" -gt 0 ]; then
		fullVersion="${possibles[0]}"
	fi

	if [ -z "$fullVersion" ]; then
		echo >&2
		echo >&2 "error: unable to determine available releases of $version"
		echo >&2
		exit 1
	fi

	url='https://varnish-cache.org/_downloads/varnish-'"$fullVersion"'.tgz'
	sha256=$(wget -qO- -o /dev/null "$url" | sha256sum - | awk '{print $1}')

	dockerfiles=()

	for suite in stretch alpine{3.7}; do
		[ -d "$version/$suite" ] || continue
		alpineVer="${suite#alpine}"

		baseDockerfile=Dockerfile-debian.template
		if [ "${suite#alpine}" != "$suite" ]; then
			baseDockerfile=Dockerfile-alpine.template
		fi

		{ generated_warning; cat "$baseDockerfile"; } > "$version/$suite/Dockerfile"

		echo "Generating $version/$suite/Dockerfile from $baseDockerfile"

		cp -a \
			docker-varnish-entrypoint \
			docker-varnish-source \
			"$version/$suite/"

		sed -ri \
			-e 's!%%DEBIAN_SUITE%%!'"$suite"'-slim!' \
			-e 's!%%ALPINE_VERSION%%!'"$alpineVer"'!' \
			"$version/$suite/Dockerfile"
		dockerfiles+=( "$version/$suite/Dockerfile" )
	done

	(
		set -x
		sed -ri \
			-e 's!%%VARNISH_VERSION%%!'"$fullVersion"'!' \
			-e 's!%%VARNISH_URL%%!'"$url"'!' \
			-e 's!%%VARNISH_SHA256%%!'"$sha256"'!' \
			"${dockerfiles[@]}"
	)

	newTravisEnv=
	for dockerfile in "${dockerfiles[@]}"; do
		dir="${dockerfile%Dockerfile}"
		dir="${dir%/}"
		variant="${dir#$version}"
		variant="${variant#/}"
		newTravisEnv+='\n  - VERSION='"$version VARIANT=$variant"
	done
	travisEnv="$newTravisEnv$travisEnv"
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
