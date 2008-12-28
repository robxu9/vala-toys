
#Build in these directories:
SUBDIRS = gen-project doc

if HAVE_VSC
SUBDIRS += vsc
endif

if HAVE_VTGPLUGIN
SUBDIRS += vtg images ui po
endif

if HAVE_VSCSHELL
SUBDIRS += vsc-shell
endif

vtgdocdir = ${prefix}/doc/vtg
vtgdoc_DATA = \
        README\
        COPYING-GPL\
        COPYING-LGPL\
	COPYING \
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
