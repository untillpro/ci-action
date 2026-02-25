#!/usr/bin/env bash
set -Eeuo pipefail

declare -A tinygo_versions=(
  ["1.24"]="0.37.0"
  ["1.25"]="0.39.0"
  ["1.26"]="0.40.1"
)

ver="${1-}"

if [ -z "$ver" ]; then
  echo "First arg must contain Go version" >&2
  exit 1
fi

if [[ "$ver" == *.*.* ]]; then
  go_minor="${ver%.*}"
else
  go_minor="$ver"
fi

tinygo_version="${tinygo_versions[$go_minor]-}"

if [ -z "$tinygo_version" ]; then
  echo "No TinyGo version mapping for Go version $go_minor (full: $ver)" >&2
  exit 1
fi

package="tinygo_${tinygo_version}_amd64.deb"
url="https://github.com/tinygo-org/tinygo/releases/download/v${tinygo_version}/${package}"

# Download and install tinygo
wget "$url"
sudo dpkg -i "$package"
