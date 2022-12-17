.PHONY: build rsync clean cleancache 

RSYNC_TARGET:=kvm:/srv/tftp/457c5ec9/

build:
	./bin/build.sh

rsync:
	rsync -vvah ./dist/ "${RSYNC_TARGET}" --delete

clean:
	sudo rm -rf dist temp/build temp/alpine

cleancache:
	sudo rm -rf temp
