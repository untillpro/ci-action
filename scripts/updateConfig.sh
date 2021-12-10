#!/bin/bash

branch=$(git symbolic-ref --short HEAD)

stack="alpha2"
if [[ $branch =~ "release" ]]; then
  stack="release"
fi
if [[ $branch =~ "rc" ]]; then
  stack="rc"
fi

stackfile="./airs-config-sync/stacks/$stack/stack.yml"
if [ ! -f "$stackfile"  ]
then
    echo "File $stackfile not found "
    exit 1
fi

if [[ $branch =~ "release" ]]; then
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
    if [[ $line =~ $pack ]]; then
	packfound=1	
    fi 
  else
     if [[ $line =~ "$updtag:" ]]; then
       sed -i "${i}s/.*$updtag.*/      $reptag: $tagvalue/" ${stackfile}
       break
     fi
  fi
done < ${stackfile}

