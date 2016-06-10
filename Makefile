RELEASE=3.4

PACKAGE=pve-cluster
PKGVER=3.0
PKGREL=20

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
GITVERSION:=$(shell cat .git/refs/heads/master)

DEB=${PACKAGE}_${PKGVER}-${PKGREL}_${ARCH}.deb
DBG_DEB=${PACKAGE}-dbg_${PKGVER}-${PKGREL}_${ARCH}.deb



all: ${DEB} ${DBG_DEB}

cpgtest: cpgtest.c
	gcc -Wall cpgtest.c $(shell pkg-config --cflags --libs libcpg libcoroipcc) -o cpgtest

.PHONY: dinstall
dinstall: ${DEB} ${DBG_DEB}
	dpkg -i ${DEB} ${DBG_DEB}

.PHONY: ${DEB} ${DBG_DEB}
${DEB} ${DBG_DEB}:
	rm -rf build
	rsync -a --exclude .svn data/ build
	cp -a debian build/debian
	echo "git clone git://git.proxmox.com/git/pve-cluster.git\\ngit checkout ${GITVERSION}" > build/debian/SOURCE
	cd build; ./autogen.sh
	cd build; dpkg-buildpackage -rfakeroot -b -us -uc
	lintian ${DEB}


.PHONY: upload
upload: ${DEB} ${DBG_DEB}
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o rw 
	mkdir -p /pve/${RELEASE}/extra
	rm -f /pve/${RELEASE}/extra/${PACKAGE}*.deb
	rm -f /pve/${RELEASE}/extra/Packages*
	cp ${DEB} ${DBG_DEB} /pve/${RELEASE}/extra
	cd /pve/${RELEASE}/extra; dpkg-scanpackages . /dev/null > Packages; gzip -9c Packages > Packages.gz
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o ro

.PHONY: clean
clean:
	rm -rf *~ build *_${ARCH}.deb *.changes *.dsc ${CSDIR}
