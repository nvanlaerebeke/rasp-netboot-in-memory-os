.PHONY: build rsync clean cleancache 

PROJECT:=rasp-in-memory
VERSION:=$(shell cat VERSION | head -1)
PWD:=`pwd`
DIST_DIR:=${PWD}/dist
TMP_DIR:=${PWD}/temp
RSYNC_TARGET:=

container: clean
	docker build -t "${PROJECT}/${VERSION}" .

build: clean
	echo "Using output directory ${DIST_DIR}" 
	echo "Caching sources (alpine kernel and root filesystem) in ${TMP_DIR}"

	docker run --rm -ti \
		--name ${PROJECT} \
		-v "${PWD}:/build" \
		--privileged \
		"${PROJECT}/${VERSION}"

run:
	${PWD}/bin/build.sh

build-no-custom-container:
	docker run --rm -ti --name ${PROJECT} -v `pwd`:/build -w "/build" --privileged ubuntu:22.04 bash /build/bin/build.sh

rsync:
	rsync -vvah ./dist/ "${RSYNC_TARGET}" --delete

clean:
	sudo rm -rf dist temp/build temp/alpine

cleancache:
	sudo rm -rf temp
