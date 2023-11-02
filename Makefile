.PHONY: build rsync clean cleancache 

RSYNC_TARGET:=

build:
	docker run --rm -ti --name rasp-build -v `pwd`:/build -w "/build" --privileged ubuntu:22.04 bash /build/bin/build.sh

rsync:
	rsync -vvah ./dist/ "${RSYNC_TARGET}" --delete

clean:
	sudo rm -rf dist temp/build temp/alpine

cleancache:
	sudo rm -rf temp
