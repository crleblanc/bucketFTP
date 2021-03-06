#!/bin/bash -e

# Builds Docker images bucketFTP
#
# Builds a statically linked executable and adds it to the container.
#
# usage: ./build.sh

# code will be compiled in this container
BUILD_CONTAINER=golang:1.7.3-alpine

DOCKER_TMP="docker-build-tmp"
VERSION='git-'`git rev-parse --short HEAD`

# The current working dir to use in GOBIN etc e.g., geonet-web
CWD=${PWD##*/}

mkdir -p ${DOCKER_TMP}/etc/ssl/certs
mkdir -p ${DOCKER_TMP}/usr/share

# Assemble common resource for ssl and timezones from the build container
docker run --rm -v ${PWD}:${PWD} ${BUILD_CONTAINER} \
    /bin/ash -c "apk add --update ca-certificates tzdata && \
    cp /etc/ssl/certs/ca-certificates.crt ${PWD}/${DOCKER_TMP}/etc/ssl/certs && \
    cp -Ra /usr/share/zoneinfo ${PWD}/${DOCKER_TMP}/usr/share"

pkgname=${CWD}
docker run -e "GOBIN=/usr/src/go/src/github.com/GeoNet/${pkgname}/${DOCKER_TMP}" -e GOPATH=/usr/src/go -e "CGO_ENABLED=0" -e "GOOS=linux" -e "BUILD=$BUILD" --rm \
    -v ${PWD}:/usr/src/go/src/github.com/GeoNet/${pkgname} \
    -w /usr/src/go/src/github.com/GeoNet/${pkgname} ${BUILD_CONTAINER} \
    go install -a -ldflags "-X main.Prefix=${pkgname}/${VERSION}" -installsuffix cgo .

cp Dockerfile ${DOCKER_TMP}
cd ${DOCKER_TMP}
docker build -t bucketftp:latest .
cd ..

# Use rm in docker to avoid permissions issues
docker run -v ${PWD}:${PWD} ${BUILD_CONTAINER} rm -rf ${PWD}/${DOCKER_TMP}
