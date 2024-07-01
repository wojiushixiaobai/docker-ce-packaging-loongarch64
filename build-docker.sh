#!/bin/bash
#
DOCKER_VERSION=v27.0.1

################################################################
# REF: v27.0.0
# VERSION: 27.0.0
# PACKAGE_VERSION: 27.0
#
REF=${DOCKER_VERSION}
VERSION=${REF#v}
PACKAGE_VERSION=${VERSION%.*}

TMPDIR=$(mktemp -d)

git clone --depth=1 https://github.com/docker/docker-ce-packaging "${TMPDIR}"

pushd "${TMPDIR}" || exit 1

################################################################
# GO_VERSION: 1.21
# GO_IMAGE: golang:1.21-buster
#
GO_VERSION=$(grep '^GO_VERSION' common.mk | awk -F ":=" '{print $2}' | cut -d. -f1,2)
GO_IMAGE=golang:${GO_VERSION}-buster

################################################################
# See. https://hub.docker.com/r/docker/dockerfile/tags
# docker.io/docker/dockerfile not support linux/loong64
#
cp -R deb/debian-bullseye deb/debian-buster
sed -i "s@ARCHES:=amd64@ARCHES:=loong64 amd64@g" common.mk
sed -i "s@DEBIAN_VERSIONS ?= debian-bullseye@DEBIAN_VERSIONS ?= debian-bullseye debian-buster@g" deb/Makefile
sed -i "s@ARG SUITE=bullseye@ARG SUITE=buster@g" deb/debian-buster/Dockerfile
sed -i "s@ARG VERSION_ID=11@ARG VERSION_ID=10@g" deb/debian-buster/Dockerfile
sed -i '/syntax=docker/d' deb/debian-buster/Dockerfile

make REF=${REF} VERSION=${VERSION} GO_VERSION=${GO_VERSION} GO_IMAGE=${GO_IMAGE} debian-buster

popd || exit 1

mkdir -p dist
mv ${TMPDIR}/deb/debbuild/debian-buster/* dist/

rm -rf "${TMPDIR:?}"