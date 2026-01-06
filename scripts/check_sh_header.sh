#!/usr/bin/env bash
set -Eeuo pipefail

# Check that all .sh files start with the required header:
#   #!/usr/bin/env bash
#   set -Eeuo pipefail
# ignoring leading blank lines and pure comment lines.

echo "Checking .sh files for required header..."

# Find all .sh files, excluding .git directory
sh_files=$(find . -type f -name '*.sh' -not -path './.git/*')

if [ -z "${sh_files}" ]; then
  echo "No .sh files found; skipping."
  exit 0
fi

err=0

while IFS= read -r file; do
  [ -z "${file}" ] && continue

  # Use a single awk pass per file for speed
  if ! awk -v file="${file}" '
    function trim(s) {
      sub(/^[ \t\r]+/, "", s);
      sub(/[ \t\r]+$/, "", s);
      return s;
    }

    # State
    BEGIN {
      count = 0;
      bad = 0;
    }

    {
      raw = $0;

      # Skip blank lines
      t = raw; sub(/^[ \t\r]+/, "", t);
      if (t == "") next;

      # Skip comments except shebang
      if (substr(t, 1, 1) == "#" && substr(raw, 1, 2) != "#!") next;

      # Meaningful line
      count++;
      line = trim(raw);

      if (count == 1) {
        if (!(line ~ /^#!\/usr\/bin\/env[ \t]+bash([ \t]|$)/)) {
          printf "::error file=%s::Missing or incorrect shebang #!/usr/bin/env bash at the beginning of the file\n", file;
          bad = 1;
        }
      }
      else if (count == 2) {
        if (!(line ~ /^set[ \t]+-Eeuo[ \t]+pipefail([ \t]|$)/)) {
          printf "::error file=%s::Missing set -Eeuo pipefail immediately after the shebang (ignoring comments/blank lines)\n", file;
          bad = 1;
        }
        exit bad;
      }
    }

    END {
      if (count == 0) {
        printf "::error file=%s::Missing or incorrect shebang #!/usr/bin/env bash at the beginning of the file\n", file;
        printf "::error file=%s::Missing set -Eeuo pipefail immediately after the shebang (ignoring comments/blank lines)\n", file;
        exit 1;
      } else if (count == 1) {
        printf "::error file=%s::Missing set -Eeuo pipefail immediately after the shebang (ignoring comments/blank lines)\n", file;
        exit 1;
      }
      exit bad;
    }
  ' "${file}"; then
    err=1
  fi
done <<< "${sh_files}"

if [ "${err}" -ne 0 ]; then
  echo "Shell script header check failed."
  exit 1
fi

echo "Shell script header check passed."
