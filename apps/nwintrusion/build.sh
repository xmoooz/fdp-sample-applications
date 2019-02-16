#!/usr/bin/env bash

set -eu
: ${NOOP:=}

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"

source $HERE/../../common.sh

docker_task="docker"
push_msg=
while [[ $# -gt 0 ]]
do
  case $1 in
     --push|--push-docker-images)
      docker_task="dockerBuildAndPush"
      push_msg="Pushed the docker images."
      ;;
    -v|--version*)
      shift
      VERSION=$(get_version $@)
      ;;
    *)
      error "Unrecognized argument $1"
      ;;
  esac
  shift
done

[[ -n $VERSION ]] || error "Version string can't be empty!"
info2 "Using version $VERSION"

cd ${HERE}
$NOOP bats test/bin/*.bats

echo "nwintrusion: VERSION = $VERSION"
cd ${HERE}/source/core
for i in fdp-nwintrusion-ingestion fdp-nwintrusion-anomaly fdp-nwintrusion-batchkmeans
do
  $NOOP sbt -DK8S_OR_DCOS=K8S -no-colors "set version in ThisBuild := \"$VERSION\"" "show version" $i/clean $i/$docker_task
done

echo "$PWD: built package and Docker images. $push_msg"
