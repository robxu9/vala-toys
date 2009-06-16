NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(VSC_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = libvsc.vala.stamp


if ENABLE_DEBUG
        DEBUG = --Xcc "-g" --Xcc "-O0"
else
        DEBUG = --Xcc "-D G_DISABLE_DEBUG"
endif

libvsc_ladir = $(libdir)/gedit-2/plugins
libvscdir = $(libdir)/gedit-2/plugins

noinst_LTLIBRARIES = libvsc.la

vsc_VALASOURCES = \
	vscsymbolcompletion.vala \
	vscsymbolcompletionfilteroptions.vala \
	vscsymbolcompletionitem.vala \
	vscsymbolcompletionresult.vala \
	vscsourcebuffer.vala \
	vscmethodlistvisitor.vala \
	vscclasslistvisitor.vala \
	vsccompletionvisitor.vala \
	vsctypefindvisitor.vala \
	vscparsermanager.vala \
	$(NULL)

noinst_HEADERS = \
	vsc.h \
	$(NULL)

libvsc_la_SOURCES = \
	libvsc.vala.stamp \
	$(vsc_VALASOURCES:.vala=.c) \
	$(NULL)

libvsc.vala.stamp: $(vsc_VALASOURCES)
	$(VALAC) $(DEBUG) -C --vapidir ../vapi --pkg config --pkg vala-1.0  --pkg utils -H vsc.h --library vsc-1.0 $^
	touch $@

libvsc_la_LDFLAGS = \
	-static \
	$(NULL)

libvsc_la_LIBADD = \
	$(VSC_LIBS) \
	$(NULL)

libvsc_la_DATA = \
	$(NULL)

EXTRA_DIST = \
	$(vsc_VALASOURCES) \
	libvsc.vala.stamp \
	$(NULL)

DISTCLEANFILES = \
	$(NULL)

