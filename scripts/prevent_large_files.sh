#!/bin/sh

fc=$1
fs=$2

if [ $fs -gt 2 ]
then
	cat <<\EOF
	Error: Attempt to Commit too much files

EOF
	exit 1
fi

if [ $fs -gt 1000 ]
then
	cat <<\EOF
	Error: Attempt to Commit large file

EOF
	exit 1
fi
