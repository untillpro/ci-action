#!/usr/bin/env bash
set -Eeuo pipefail

br=""
if git rev-parse --git-dir > /dev/null 2>&1; then
  br=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")
fi

# Fallback to the environment variable 'branch' if 'br' is empty
if [ -z "$br" ]; then
  br="$branch"
fi
echo "Branch: $br"

stack="dev"
if [[ $br =~ "release" ]]; then
  stack="euro"
fi
if [[ $br =~ "rc" ]]; then
  stack="rc"
fi
echo "Stack: $stack"

stackfile="./airs-config-sync/stacks/$stack/stack.yml"
if [ ! -f "$stackfile"  ]
then
    echo "File $stackfile not found "
    exit 1
fi

if [[ $br =~ "release" ]]; then
  updtag="tag"
  reptag="  tag"
  tagvalue=$tag
else
  # take current year value
  updtag="created"
  reptag="created"
  curyear=$(date +'%Y')
  curmonth=$(date +'%m')
  curday=$(date +'%d')
  curhour=$(date +'%H')
  curmin=$(date +'%M')
  tagvalue=${curyear}${curmonth}${curday}${curhour}${curmin}
fi

i=0
packfound=0
while read -r line; do
  i=$((i+1))
  if [ $packfound -eq 0 ]; then
    if [[ $line =~ "pack: $pack" ]]; then
	packfound=1
    fi
  else
     if [[ $line =~ "$updtag:" ]]; then
       sed -i "${i}s/.*$updtag.*/      $reptag: $tagvalue/" ${stackfile}
       break
     fi
  fi
done < ${stackfile}

