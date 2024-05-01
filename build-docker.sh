#!/bin/bash
#
DOCKER_VERSION=v26.1.1

################################################################
# REF: v24.0.7
# VERSION: 24.0.7
# PACKAGE_VERSION: 24.0
#
REF=${DOCKER_VERSION}
VERSION=${REF#v}
PACKAGE_VERSION=${VERSION%.*}

TMPDIR=$(mktemp -d)

git clone -b "${PACKAGE_VERSION}" --depth=1 https://github.com/docker/docker-ce-packaging "${TMPDIR}" || git clone --depth=1 https://github.com/docker/docker-ce-packaging "${TMPDIR}"
cp docker.patch "${TMPDIR}"

pushd "${TMPDIR}" || exit 1

################################################################
# GO_VERSION: 1.20
# GO_IMAGE: golang:1.20-buster
#
GO_VERSION=$(grep '^GO_VERSION' common.mk | awk -F ":=" '{print $2}' | cut -d. -f1,2)
GO_IMAGE=golang:${GO_VERSION}-buster

################################################################
# See. https://hub.docker.com/r/docker/dockerfile/tags
# docker.io/docker/dockerfile not support linux/loong64
#
sed -i "s@ARCHES:=amd64@ARCHES:=loong64 amd64@g" common.mk
sed -i '/syntax=docker/d' deb/debian-buster/Dockerfile

################################################################
# See. https://github.com/moby/moby
# vendor/github.com/cilium/ebpf not support linux/loong64
#
git apply docker.patch || exit 1

make REF=${REF} VERSION=${VERSION} GO_VERSION=${GO_VERSION} GO_IMAGE=${GO_IMAGE} debian-buster

popd || exit 1

mkdir -p dist
mv ${TMPDIR}/deb/debbuild/debian-buster/* dist/

rm -rf "${TMPDIR:?}"