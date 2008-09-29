
#Build in these directories:
SUBDIRS = vsc vsc-shell vtg images po

vtgdocdir = ${prefix}/doc/vtg
vtgdoc_DATA = \
        README\
        COPYING-GPL\
        COPYING-LGPL\
	LICENSE-NOTE \
        AUTHORS\
        ChangeLog\
        INSTALL\
        NEWS

EXTRA_DIST = $(vtgdoc_DATA) \
        intltool-extract.in \
        intltool-merge.in \
        intltool-update.in 

DISTCLEANFILES = \
        intltool-extract \
        intltool-merge \
        intltool-update

# Copy all the spec files. Of cource, only one is actually used.
# dist-hook:
	for specfile in *.spec; do \
		if test -f $$specfile; then \
			cp -p $$specfile $(distdir); \
		fi \
	done
