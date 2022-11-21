#!/bin/sh

fc=$1
fs=$2
echo "$1"
echo "$2"

if [ $fc -gt 2 ]
then
	cat <<\EOF
	Error: Attempt to Commit too much files: $fc

EOF
	exit 1
fi

if [ $fs -gt 1000 ]
then
	cat <<\EOF
	Error: Attempt to Commit large file: $fs

EOF
	exit 1
fi
