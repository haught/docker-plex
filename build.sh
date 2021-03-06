#!/bin/sh
set -e

if [ "$1" == "--check" ] || [ "$1" == "-c" ]; then
  CHECKONLY=true
fi

URL=$(curl -Ls https://plex.tv/api/downloads/1.json | jq '.computer.Linux.releases[] |select(.distro=="debian" and .build=="linux-x86_64") .url' | sed -e 's/"//g')
VERSION=$(echo $URL | cut -d\/ -f5)

git pull > /dev/null 2>&1
DOCKERFILE_VERSION=$(grep "^ARG PLEX_VERSION=" Dockerfile | cut -f2 -d\=)

if [ "${VERSION}" != "${DOCKERFILE_VERSION}" ]; then
  if [ "${CHECKONLY}" == "true" ]; then
    echo "There is a new version available"
    echo "Current version: ${DOCKERFILE_VERSION}"
    echo "Available version: ${VERSION}"
    exit 0
  fi

  echo "Updating Dockerfile with version ${VERSION}"
  sed -i -e "s/^\(ARG PLEX_VERSION=\).*$/\1${VERSION}/g" \
         -e "s|^\(ARG PLEX_URL=\).*$|\1${URL}|g" Dockerfile
  git add Dockerfile
  git commit -m "Bumping Plex version to ${VERSION}"
  git push
  make minor-release
  exit -1
else
  make build
  make push
  echo "No change"
fi

# exit codes:
# 0 - no action
# -1 - new build pushed
# rest - errors
