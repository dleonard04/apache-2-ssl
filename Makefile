SHELL=/bin/sh

current_dir:=$(shell pwd)
changelog:=$(current_dir)/debian/changelog

pkgname:=$(shell head -n 1 $(changelog) | \
           awk '{print $$1}')

version:=$(shell head -n 1 $(changelog) | \
           awk '{print $$2}' | \
           sed 's+[\(\)]++g')

pkg_ver:=$(pkgname)_$(version)

src_dir:=$(current_dir)/$(pkg_ver)
usr_dir:=$(current_dir)/usr

# DESTDIR is set by dpkg build process
dest_dir:=$(DESTDIR)/usr/local/apache

pkg_dist.dir?=/var/tmp

build: pre bld post

bld:
	$(MAKE) -C $(src_dir)

cfg: pre cfg-deb post

cfg-deb:
	cd $(src_dir) ; \
	 ./configure --prefix=$(dest_dir) \
	             --enable-ssl \
	             --enable-headers \
	             --enable-expires \
	             --enable-static-htpasswd \
	             --enable-http \
	             --enable-info \
	             --enable-cgi \
	             --enable-rewrite \
	             --enable-v4-mapped \
	             --enable-vhost-alias

install: pre install-files prune fix post

install-files:
	mkdir -p $(dest_dir)
	$(MAKE) -C $(src_dir) install

prune:
	-rmdir $(dest_dir)/logs
	-rm -r $(dest_dir)/man
	-rm -r $(dest_dir)/manual
	-rm $(dest_dir)/htdocs/index.html.*
	-rm $(dest_dir)/htdocs/apache_pb*
	-rm $(dest_dir)/conf/*

fix:
	if [ -d $(usr_dir)/files ]; then \
	 cp -r $(usr_dir)/files/* $(DESTDIR)/. ; \
	 find $(DESTDIR) -type d -name CVS | xargs rm -r ; \
	fi
	mkdir -p $(DESTDIR)/var/log/apache

dist:
	cp ../$(pkg_ver)_i386.deb $(pkg_dist.dir)

all bin-pkg:
	dpkg-buildpackage -B

src-pkg:
	dpkg-buildpackage -S

pre:
	if ! [ -d $(pkg_ver) ]; then mv src $(pkg_ver) ; fi

post:
	if [ -d $(pkg_ver) ]; then mv $(pkg_ver) src ; fi

# Clean targets
clean-debian:
	debian/rules clean

clean-src:
	cp -a $(src_dir)/.deps $(src_dir)/.deps.bak
	-$(MAKE) -C $(src_dir) distclean
	mv $(src_dir)/.deps.bak $(src_dir)/.deps

	# Some stuff apache's clean doesn't take care of
	-rm $(src_dir)/build/pkg/pkginfo
	-rm $(src_dir)/config.nice
	-rm $(src_dir)/docs/conf/ssl-std.conf
	-rm $(src_dir)/os/beos/.deps
	-rm $(src_dir)/os/beos/Makefile
	-rm $(src_dir)/os/os2/.deps
	-rm $(src_dir)/os/os2/Makefile
	-rm $(src_dir)/server/export_files
	-rm $(src_dir)/server/exports.c
	-rm $(src_dir)/srclib/apr/build/pkg/pkginfo
	-rm $(src_dir)/srclib/apr/config.nice
	-rm $(src_dir)/srclib/apr/test/internal/Makefile
	-rm $(src_dir)/srclib/apr-util/build/pkg/pkginfo
	-rm $(src_dir)/srclib/apr-util/config.nice

clean-dst:
	-rm -rf $(dst_dir)

clean-pkg:
	-rm ../$(pkg_ver).dsc
	-rm ../$(pkg_ver).tar.gz
	-rm ../$(pkg_ver)_source.changes
	-rm ../$(pkg_ver)_i386.deb 
	-rm ../$(pkg_ver)_i386.changes

clean-most: pre clean-debian clean-src clean-dst post
distclean clean-all: pre clean-debian clean-src clean-dst clean-pkg post

.PHONY: clean
