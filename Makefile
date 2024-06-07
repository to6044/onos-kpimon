# SPDX-FileCopyrightText: 2019-present Open Networking Foundation <info@opennetworking.org>
#
# SPDX-License-Identifier: Apache-2.0

export CGO_ENABLED=1
export GO111MODULE=on

.PHONY: build

TARGET := onos-kpimon
TARGET_VERSION := ${DOCKER_TAG}
ONOS_PROTOC_VERSION := v0.6.6
BUF_VERSION := 0.27.1

build: # @HELP build the Go binaries and run all validations (default)
build:
	GOPRIVATE="github.com/onosproject/*" go build -o build/_output/onos-kpimon ./cmd/onos-kpimon

build-tools:=$(shell if [ ! -d "./build/build-tools" ]; then cd build && git clone https://github.com/onosproject/build-tools.git; fi)
include ./build/build-tools/make/onf-common.mk



# kpimon-docker: # @HELP build onos-kpimon Docker image
# kpimon-docker:
# 	@go mod vendor
# 	docker build . -f build/onos-kpimon/Dockerfile \
# 		-t khusdran/onos-kpimon:${ONOS_KPIMON_VERSION}
# 	@rm -rf vendor

target-docker: # @HELP build target Docker image
target-docker:
	@go mod vendor
	docker build . -f build/${TARGET}/Dockerfile \
		-t ${DOCKER_REPOSITORY}${TARGET}:${TARGET_VERSION}
	@rm -rf vendor

images: # @HELP build all Docker images
images: build target-docker

docker-push:
	docker push ${DOCKER_REPOSITORY}${TARGET}:${DOCKER_TAG}

kind: # @HELP build Docker images and add them to the currently configured kind cluster
kind: images
	@if [ "`kind get clusters`" = '' ]; then echo "no kind cluster found" && exit 1; fi
	kind load docker-image onosproject/onos-kpimon:${ONOS_KPIMON_VERSION}

all: build images

publish: # @HELP publish version on github and dockerhub
	./build/build-tools/publish-version ${VERSION} onosproject/onos-kpimon

jenkins-publish: jenkins-tools # @HELP Jenkins calls this to publish artifacts
	./build/bin/push-images
	./build/build-tools/release-merge-commit

clean:: # @HELP remove all the build artifacts
	rm -rf ./build/_output ./vendor ./cmd/onos-kpimon/onos-kpimon ./cmd/onos/onos
	go clean -testcache github.com/onosproject/onos-kpimon/...

mcl_publish:
	echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin