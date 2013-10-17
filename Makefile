VERSION=11.4.4
VERSION_DEBIAN=${VERSION}-2.debian.6.0.5
VERSION_SUFFIX=foobarbazqux

WORK_DIR=chef11

DISTRIBUTION="wheezy"
MAINTAINER=fpm <fpm@localhost>
DATE=`LANG=C date '+%a, %d %b %Y %I:%M:%S %z'`

all: fpm

chef11.tgz:
	wget http://staff.0x50.net/~aga/chef/omnibus-chef11/$@

${WORK_DIR}: chef_${VERSION_DEBIAN}_amd64.deb
	mkdir -p ${WORK_DIR}
	dpkg -x $< ${WORK_DIR}/data
	dpkg -e $< ${WORK_DIR}/control

reversion: ${WORK_DIR}
	sed -i -e 's/^Version.*/Version: ${VERSION_DEBIAN}.${VERSION_SUFFIX}/' ${WORK_DIR}/control/control

post-patch: chef11.tgz
	tar zxvf $< chef11/control/postinst
	tar zxvf $< chef11/control/prerm
	tar zxvf $< chef11/data/etc/default/chef-client
	tar zxvf $< chef11/data/etc/init.d/chef-client

${WORK_DIR}/changelog:
	echo "chef (${VERSION}.${VERSION_SUFFIX}) ${DISTRIBUTION}; urgency=low\n\n  * Build by fpm\n -- ${MAINTAINER}  ${DATE}\n" > $@

${WORK_DIR}/files:
	echo "chef_${VERSION_DEBIAN}_amd64.deb utils extra" > $@

${WORK_DIR}/control-custom:
	echo "Source: chef\nSection: utils\nStandards-Version: 3.9.1\nPriority: extra\n" > $@
	sed -e 's/Section: .*/Section: utils/' ${WORK_DIR}/control/control >> $@

fpm: reversion post-patch ${WORK_DIR}/changelog ${WORK_DIR}/control-custom ${WORK_DIR}/files
	cd ${WORK_DIR} && fpm -s dir -t deb -n chef -v ${VERSION}.${VERSION_SUFFIX} --deb-custom-control control/control --after-install control/postinst --before-remove control/prerm -C data -p chef_VERSION_ARCH.deb etc opt
	mv ${WORK_DIR}/chef_${VERSION}.${VERSION_SUFFIX}_amd64.deb ./
	dpkg-genchanges -b -c${WORK_DIR}/control-custom -l${WORK_DIR}/changelog -f${WORK_DIR}/files "-m${MAINTAINER}" -u. > chef_${VERSION}.${VERSION_SUFFIX}_amd64.changes

clean:
	rm -rf ${WORK_DIR}

mrproper: clean
	rm chef_${VERSION_DEBIAN}-amd64.deb
