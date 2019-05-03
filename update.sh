#!/bin/bash
set -e

declare -A repoGpgKeys=(
	[varnish41]='14251B49A184B44E00B22B85FDBCAE9C0FC6FD2E'
	[varnish60lts]='DD2C378724BD39C18AAA47FE3AEAFFBB82FBBA5F'
	[varnish62]='9AE5C23F70B8BADF1B155DEE0D42823DD1135F8E'
)

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

	case "$version" in
		4.1)
			repoName=varnish41
			;;
		6.0)
			repoName=varnish60lts
			;;
		6.2)
			repoName=varnish62
			;;
		*)
			echo >&2
			echo >&2 "error: unable to determine repository name for $version"
			echo >&2
			exit 1
			;;
	esac
	repoUrl=https://packagecloud.io/varnishcache/$repoName/debian/
	repoGpgKeyUrl=https://packagecloud.io/varnishcache/$repoName/gpgkey
	repoGpgKey="${repoGpgKeys[$repoName]}"

	if [ -z "$repoGpgKey" ]; then
		echo >&2
		echo >&2 "error: missing GPG key fingerprint for $version"
		echo >&2
		exit 1
	fi

	declare -A suitePackageList=()
	declare -A suiteArches=(
		[stretch]='amd64'
	)

	dockerfiles=()

	for variant in stretch alpine3.8; do
		[ -d "$version/$variant" ] || continue
		alpineVer="${variant#alpine}"

		case "$variant" in
			stretch)
				suite=$variant
				if [ -z "${suitePackageList[$suite]:+isset}" ]; then
					suitePackageList["$suite"]="$(curl -fsSL "${repoUrl}/dists/${suite}/main/binary-amd64/Packages.bz2" | bunzip2)"
				fi
				# if [ -z "${suiteArches[$suite]:+isset}" ]; then
				# 	suiteArches["$suite"]="$(curl -fsSL "${repoUrl}/dists/${suite}/Release" | gawk -F ':[[:space:]]+' '$1 == "Architectures" { gsub(/[[:space:]]+/, "|", $2); print $2 }')"
				# fi

				packageVersion="$(echo "${suitePackageList[$suite]}" | awk -F ': ' '$1 == "Package" { pkg = $2 } $1 == "Version" && pkg == "varnish" { print $2; exit }' || true)"
				;;
		esac

		baseDockerfile=Dockerfile-debian.template
		if [ "${variant#alpine}" != "$variant" ]; then
			baseDockerfile=Dockerfile-alpine.template
		fi

		{ generated_warning; cat "$baseDockerfile"; } > "$version/$variant/Dockerfile"

		echo "Generating $version/$variant/Dockerfile from $baseDockerfile"

		cp -a \
			docker-varnish-entrypoint \
			"$version/$variant/"

		sed -ri \
			-e 's!%%DEBIAN_TAG%%!'"$variant"'-slim!' \
			-e 's!%%DEBIAN_SUITE%%!'"$suite"'!' \
			-e 's!%%ALPINE_VERSION%%!'"$alpineVer"'!' \
			-e 's!%%VARNISH_VERSION%%!'"$fullVersion"'!' \
			-e 's!%%VARNISH_URL%%!'"$url"'!' \
			-e 's!%%VARNISH_SHA256%%!'"$sha256"'!' \
			-e 's!%%VARNISH_PACKAGE_VERSION%%!'"$packageVersion"'!' \
			-e 's!%%VARNISH_REPO_URL%%!'"$repoUrl"'!' \
			-e 's!%%VARNISH_REPO_GPG_KEY_URL%%!'"$repoGpgKeyUrl"'!' \
			-e 's!%%VARNISH_REPO_GPG_KEY_FINGERPRINT%%!'"$repoGpgKey"'!' \
			-e 's!%%ARCH_LIST%%!'"${suiteArches[$suite]}"'!' \
			"$version/$variant/Dockerfile"
		dockerfiles+=( "$version/$variant/Dockerfile" )
	done

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
