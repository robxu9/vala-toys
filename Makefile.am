NULL=

#Build in these directories:
SUBDIRS = doc vapi

ACLOCAL_AMFLAGS = -I m4

if HAVE_AFRODITE
SUBDIRS += afrodite
endif

if HAVE_GENPROJECT
SUBDIRS += gen-project
endif

if HAVE_VTGPLUGIN
SUBDIRS += vbf vtg images ui po
endif

vtgdocdir = ${prefix}/doc/vtg
vtgdoc_DATA = \
        README\
        COPYING-GPL\
        COPYING-LGPL\
	COPYING \
        AUTHORS\
        INSTALL\
        NEWS

# Copy all the spec files. Of cource, only one is actually used.
# dist-hook:
	for specfile in *.spec; do \
		if test -f $$specfile; then \
			cp -p $$specfile $(distdir); \
		fi \
	done


all: version.h

version.h: $(top_srcdir)/.version
	echo '#define BUILD_VERSION "'`cat $(top_srcdir)/.version`'"' > $@-t && mv $@-t $@

BUILT_SOURCES = $(top_srcdir)/.version
$(top_srcdir)/.version: gen-version
	@true
.PHONY: gen-version
gen-version:
	@V=`$(top_srcdir)/build-aux/git-version-gen $(top_srcdir)/.tarball-version` &&			\
	if [ -e $(top_srcdir)/.version ] && [ "x`cat $(top_srcdir)/.version`" = "x$$V" ]; then		\
	  true;												\
	else												\
	  echo "$$V" > $(top_srcdir)/.version;								\
	fi
dist-hook: gen-ChangeLog
	echo $(VERSION) > $(distdir)/.tarball-version

gen_start_date = 2009-01-23
.PHONY: gen-ChangeLog
gen-ChangeLog:
	if test -d .git; then						\
	  $(top_srcdir)/build-aux/gitlog-to-changelog			\
	    --since=$(gen_start_date) > $(distdir)/cl-t;		\
	  rm -f $(distdir)/ChangeLog;					\
	  mv $(distdir)/cl-t $(distdir)/ChangeLog;			\
	fi

CLEANFILES = \
	$(NULL)

EXTRA_DIST = \
	$(vtgdoc_DATA) \
	ChangeLog.pre-2011 \
	MAINTAINERS \
	intltool-extract.in \
	intltool-merge.in \
	intltool-update.in \
	.version \
	build-aux/git-version-gen \
	build-aux/gitlog-to-changelog \
	$(NULL)

DISTCLEANFILES = version.h \
        intltool-extract \
        intltool-merge \
        intltool-update \
	$(NULL)
