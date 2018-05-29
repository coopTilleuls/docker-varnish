#!/usr/bin/env bash
set -Eeuo pipefail

declare -A aliases=(
	[4.1]='4'
	[6.0]='6 latest'
)

defaultDebianSuite='stretch'
defaultAlpineVersion='3.7'

self="$(basename "$BASH_SOURCE")"
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( */ )
versions=( "${versions[@]%/}" )

# sort version numbers with highest first
IFS=$'\n'; versions=( $(echo "${versions[*]}" | sort -rV) ); unset IFS

# get the most recent commit which modified any of "$@"
fileCommit() {
	git log -1 --format='format:%H' HEAD -- "$@"
}

# get the most recent commit which modified "$1/Dockerfile" or any file COPY'd from "$1/Dockerfile"
dirCommit() {
	local dir="$1"; shift
	(
		cd "$dir"
		fileCommit \
			Dockerfile \
			$(git show HEAD:./Dockerfile | awk '
				toupper($1) == "COPY" {
					for (i = 2; i < NF; i++) {
						print $i
					}
				}
			')
	)
}

getArches() {
	local repo="$1"; shift
	local officialImagesUrl='https://github.com/docker-library/official-images/raw/master/library/'

	eval "declare -g -A parentRepoToArches=( $(
		find -name 'Dockerfile' -exec awk '
				toupper($1) == "FROM" && $2 !~ /^('"$repo"'|scratch|microsoft\/[^:]+)(:|$)/ {
					print "'"$officialImagesUrl"'" $2
				}
			' '{}' + \
			| sort -u \
			| xargs bashbrew cat --format '[{{ .RepoName }}:{{ .TagName }}]="{{ join " " .TagEntry.Architectures }}"'
	) )"
}
getArches 'varnish'

cat <<-EOH
# this file is generated via https://github.com/coopTilleuls/docker-varnish/blob/$(fileCommit "$self")/$self

Maintainers: Teoh Han Hui <teohhanhui@gmail.com> (@teohhanhui)
GitRepo: https://github.com/coopTilleuls/docker-varnish.git
EOH

# prints "$2$1$3$1...$N"
join() {
	local sep="$1"; shift
	local out; printf -v out "${sep//%/%%}%s" "$@"
	echo "${out#$sep}"
}

for version in "${versions[@]}"; do
	versionAliases=(
		$version
		${aliases[$version]:-}
	)

	# order here controls the order of the library/ file
	for variant in \
		stretch \
		alpine{3.7} \
	; do
		dir="$version/$variant"
		[ -f "$dir/Dockerfile" ] || continue

		commit="$(dirCommit "$dir")"
		fullVersion="$(git show "$commit":"$dir/Dockerfile" | awk '$1 == "ENV" && $2 == "VARNISH_VERSION" { print $3; exit }')"

		baseAliases=( $fullVersion "${versionAliases[@]}" )
		variantAliases=( "${baseAliases[@]/%/-$variant}" )
		variantAliases=( "${variantAliases[@]//latest-/}" )

		variantAliases+=( "${baseAliases[@]}" )

		if [ "${variant#alpine}" = "$defaultAlpineVersion" ] ; then
			variantAliases=( "${variantAliases[@]/%/-alpine}" )
		elif [ "$variant" != "$defaultDebianSuite" ]; then
			variantAliases=()
		fi
		variantAliases=( "${variantAliases[@]//latest-/}" )

		variantParent="$(awk 'toupper($1) == "FROM" { print $2 }' "$dir/Dockerfile")"
		variantArches="${parentRepoToArches[$variantParent]}"

		echo
		cat <<-EOE
			Tags: $(join ', ' "${variantAliases[@]}")
			Architectures: $(join ', ' $variantArches)
			GitCommit: $commit
			Directory: $dir
		EOE
	done
done
