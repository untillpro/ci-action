#!/usr/bin/env bash
set -Eeuo pipefail

# Recursively finds every Go module under the current directory and runs
# `golangci-lint run ./...` in each module directory.
#
# A module directory is skipped if it (or any ancestor directory up to
# the starting directory) contains a `.nolint` marker file. Subdirectories of
# a directory carrying `.nolint` are skipped even when they do not have their
# own `.nolint` file.

# Select GNU find explicitly. On Windows, `find` in PATH can resolve to
# Windows' FIND.EXE when bash is launched from PowerShell/cmd, so rely on
# the Git-for-Windows copy under /usr/bin.
case "$(uname -s)" in
	# Linux, macOS: GNU/BSD find shipped with the OS.
	# MINGW/MSYS/Cygwin: Git for Windows bundles GNU find, which MSYS maps
	# to the same /usr/bin/find path.
	Linux*|Darwin*|MINGW*|MSYS*|CYGWIN*)
		FIND=/usr/bin/find
		;;
	*)
		FIND=find
		;;
esac
[ -x "$FIND" ] || command -v "$FIND" >/dev/null 2>&1 || {
	echo "error: find not found at $FIND" >&2
	exit 2
}

# Returns 0 if $1 or any ancestor up to '.' contains a `.nolint` file.
has_nolint_ancestor() {
	local d=$1

	while :; do
		if [ -f "$d/.nolint" ]; then
			return 0
		fi
		if [ "$d" = "." ]; then
			return 1
		fi
		if [[ "$d" == */* ]]; then
			d=${d%/*}
		else
			d=.
		fi
	done
}

find_prunes=(
	-path './vendor' -o -path '*/vendor'
	-o -path './node_modules' -o -path '*/node_modules'
	-o -path './.git' -o -path '*/.git'
)

failed=0
found=0
scanned_dirs=()
nolint_dirs=()

while IFS= read -r -d '' gomod; do
	dir=${gomod%/go.mod}
	dir=${dir#./}
	[ -z "$dir" ] && dir=.

	if has_nolint_ancestor "$dir"; then
		nolint_dirs+=("$dir")
		continue
	fi

	found=1
	scanned_dirs+=("$dir")

	printf '\n=== %s ===\n' "$dir"

	if ! (
		cd "$dir" &&
		golangci-lint run ./...
	); then
		failed=$((failed + 1))
	fi
done < <(
	"$FIND" . \( "${find_prunes[@]}" \) -prune -o -type f -name go.mod -print0
)

printf '\n--- summary ---\n'

if [ "$found" -eq 0 ]; then
	printf 'modules scanned: none\n'
else
	printf 'modules scanned:\n'
	for dir in "${scanned_dirs[@]}"; do
		printf '  %s\n' "$dir"
	done
fi

if [ "${#nolint_dirs[@]}" -gt 0 ]; then
	printf 'modules skipped (.nolint):\n'
	for dir in "${nolint_dirs[@]}"; do
		printf '  %s\n' "$dir"
	done
fi

printf 'modules failed:  %d\n' "$failed"

[ "$failed" -eq 0 ]
