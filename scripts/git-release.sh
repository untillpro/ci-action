#!/bin/bash

branchname="main"
# Get version from tag
s='-'
ver=$tagversion
version="${ver%$s*}"
version="${version//[[:blank:]]/}"
if [[ -z "$version" ]];then
  echo "Tag verion is not defined"
  exit 1
fi

text=""
# Get pre-release flag
prerelease="${ver#*$s}"
prerelease="${prerelease//[[:blank:]]/}"
pr=true
if [[ ${version} == ${prerelease} ]];then
   pr=false
   shver=${version}
   shrel=""
else
   version=$version-$prerelease
   shver=${version}
   shrel=${prerelease}
fi
echo "Tag will be done with version: $version"

cd ./.
buildsh="build.sh"
# Check if build.sh exists
if [[ ! -f ${buildsh} ]]; then	 
  echo "File build.sh does not exist."
  exit 1
fi

if [[ -z $branchname ]]
then 
  echo "Can not define current branch name."
  exit 1
fi	
prev_branchname=$branchname

repo_full_name=$(git config --get remote.origin.url | sed 's/.*:\/\/github.com\///;s/.git$//')

generate_post_data()
{
  cat <<EOF
{
  "tag_name": "${version}",
  "target_commitish": "${branchname}",
  "name": "${version}",
  "body": "${text}",
  "draft": false,
  "prerelease": $pr
}
EOF
}

release_id=$(curl -H "Accept: application/json" \
   -H "Authorization: token ${token}" \
   -d "$(generate_post_data)" \
   https://api.github.com/repos/$repo_full_name/releases | jq -r '.id')

if [ -z ${release_id} ] || [[ ${release_id} == null ]]; then
  echo "release_id is empty"
  exit 1
fi

echo "Making new app build..."
# Execute build.sh
shver=${shver:1}
bash build.sh ${shver} ${shrel}

builddir=".build"
echo "Check if new ".build" folder exists"
if [[ ! -d ${builddir} ]]; then	 
  echo "Folder .build does not exists. Something went wrong during building."
  exit 1
fi

cd $builddir
for fname in *
do
   if [[ ${fname} != "." ]];then
     echo "File $fname is uploading..."
     url="https://uploads.github.com/repos/$repo_full_name/releases/${release_id}/assets?name=$(basename $fname)"
     echo "url: $url"
     curl \
      -H "Authorization: token ${token}" \
      -H "Content-Type: $(file -b --mime-type $fname)" \
      --data-binary @$fname ${url}
   fi
done

echo "All files are uploaded"
