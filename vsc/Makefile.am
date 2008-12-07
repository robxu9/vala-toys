NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(VTG_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = libvsc.vala.stamp


if ENABLE_DEBUG
        DEBUG = -g
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
	vscparsermanager.vala \
	$(NULL)


libvsc_la_SOURCES = \
	$(vsc_VALASOURCES:.vala=.c) \
	$(vsc_VALASOURCES:.vala=.h) \
	$(NULL)

libvsc.vala.stamp: $(vsc_VALASOURCES)
	$(VALAC) $(DEBUG) -C  --library vsc-1.0 --vapidir ../vapi --pkg config --pkg vala-1.0 --pkg gtksourcecompletion-1.0 --pkg gedit-2.20 --pkg gtk+-2.0 --pkg gtksourceview-2.0 --pkg utils --pkg gdkkeysyms $^
	touch $@

libvsc_la_LDFLAGS = \
	-static \
	$(NULL)

libvsc_la_LIBADD = \
	$(VTG_LIBS) \
	$(NULL)

libvsc_la_DATA = \
	$(NULL)

EXTRA_DIST = \
	$(vsc_VALASOURCES) \
	libvsc.vala.stamp \
	$(NULL)

DISTCLEANFILES = \
	$(NULL)

