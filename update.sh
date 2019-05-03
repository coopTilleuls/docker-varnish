#!/bin/bash
set -e

VERSIONS="6.0 6.2"
declare -A RELEASES
RELEASES[alpine]="3.8"
#RELEASES[centos]="7"
RELEASES[debian]="stretch"
#RELEASES[ubuntu]="xenial bionic"

declare -A LTS_MAP
LTS_MAP[6.0]=yes

declare -A ALPINE_COMMITS
ALPINE_COMMITS[6.0]=d2bfb22c8e8f67ad7d8d02704f35ec4d2a19f9b9
ALPINE_COMMITS[6.2]=a55f66b0a1dbdc03b31d48e7b49b38dccf7897fb

cd "$(dirname "$0")"

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
vdr=

for version in $VERSIONS; do for dist in ${!RELEASES[@]}; do for rel in ${RELEASES[$dist]}; do
fullVersion=
	workdir=$version/$dist/$rel
	[ -d "$workdir" ] || continue

	travisEnv+="  - VERSION=$version DIST=$dist REL=$rel\n"
	case $dist in
		alpine)
			baseDockerfile=Dockerfile-alpine.template
			;;
		centos)
			baseDockerfile=Dockerfile-centos.template
			;;
		debian)
			baseDockerfile=Dockerfile-debian.template
			rel+=-slim
			;;
		ubuntu)
			baseDockerfile=Dockerfile-debian.template
			;;
		*)
			echo "Unknown distribution: $dist"
			exit 1
	esac

	if [ $dist != alpine ]; then
		if [ -n "${LTS_MAP[$version]}" ]; then
			fullVersion=$(echo $version | tr -d '.')lts
		else
			fullVersion=$(echo $version | tr -d '.')
		fi
	fi

	{ generated_warning; cat "$baseDockerfile"; } > "$workdir/Dockerfile"

	echo "Generating $workdir/Dockerfile from $baseDockerfile"

	cp -a \
		docker-varnish-entrypoint \
		"$workdir"

	sed -ri \
		-e "s!%%DISTRIBUTION%%!$dist!" \
		-e "s!%%RELEASE%%!$rel!" \
		-e 's!%%ALPINE_COMMIT%%!'"${ALPINE_COMMITS[$version]}"'!' \
		-e 's!%%VARNISH_VERSION%%!'"$fullVersion"'!' \
		"$workdir/Dockerfile"
done; done; done

echo -e "language: bash
services: docker

env:
$travisEnv"'
install:
  - git clone https://github.com/docker-library/official-images.git ~/official-images

before_script:
  - env | sort
  - cd "$VERSION/${DIST}/${REL}"
  - image="varnish:${VERSION}-${DIST}-${REL}"

script:
  - travis_retry docker build -t "$image" .
  - ~/official-images/test/run.sh "$image"

after_script:
  - docker images' > .travis.yml
