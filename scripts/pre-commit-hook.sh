#!/bin/sh

fc=$1
fs=$2
fn=$3
if [ $fc -gt 1000 ]
then
	
	echo "	Error: Attempt to Commit too much files: Files number = $fc"
	exit 1
fi

if [ $fs -gt 1000 ]
then
	echo "	Error: Attempt to Commit large file $fn: File size = $fs"
	exit 1
fi

