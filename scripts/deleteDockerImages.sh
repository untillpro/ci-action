#!/usr/bin/env bash
set -Eeuo pipefail

cntleft=10
reponame=${repo}
# get token to be able to talk to Docker Hub
TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${du}'", "password": "'${dp}'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)

# get tags for repo
IMAGE_TAGS=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${du}/${reponame}/tags/?page_size=10000 | jq -r '.results|.[]|.name')

# Initialize image list
FULL_IMAGE_LIST=""

  # build a list of images from tags
  for j in ${IMAGE_TAGS}
  do
    # add each tag to list
    FULL_IMAGE_LIST="${FULL_IMAGE_LIST} ${du}/${reponame}:${j}"
  done

idx=0
for j in ${FULL_IMAGE_LIST}
do
  idx=$((idx+1))
  if [[ $j =~ "alpha" ]]; then
	continue
  fi
  if [[ $j =~ "main" ]]; then
	continue
  fi
  if [[ $j =~ "rc" ]]; then
	continue
  fi
  if [ $idx -gt $cntleft ]
  then
       ## Please uncomment below line to delete docker hub images of docker hub repositories
	secondString="/tags/"
        j=${j/:/$secondString}
        echo "Deleting: https://hub.docker.com/v2/repositories/$j/..."
        curl -s -X DELETE  -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/$j/
        echo "Done"
  fi
done


