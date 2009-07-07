NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(VTGPLUGIN_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	-I $(top_srcdir)/vsc \
	-I $(top_srcdir)/vbf \
	$(NULL)

BUILT_SOURCES = libvtg.vala.stamp

if ENABLE_DEBUG
        DEBUG = --Xcc "-g" --Xcc "-O0"
else
	DEBUG = --Xcc "-D G_DISABLE_DEBUG"
endif

libvtgdir = $(libdir)/gedit-2/plugins

libvtg_LTLIBRARIES = libvtg.la


libvtg_la_VALASOURCES = \
	vtgbracketcompletion.vala \
	vtgsymbolcompletionprovider.vala \
	vtgsymbolcompletiontrigger.vala \
	vtgsymbolcompletionhelper.vala \
	vtgprojectmanagerui.vala \
	vtgprojectdescriptor.vala \
	vtgprojectview.vala \
	vtgprojectbuilder.vala \
	vtgprojectexecuter.vala \
	vtgprojectexecuterdialog.vala \
	vtgprojectsearch.vala \
	vtgprojectsearchresultsview.vala \
	vtgprojectsearchdialog.vala \
	vtgprocesswatchinfo.vala \
	vtgoutputview.vala \
	vtgbuildlogview.vala \
	vtgprojectmanager.vala \
	vtgfilteredlistdialog.vala \
	vtgvcsbackendsivcs.vala \
	vtgvcsbackendsgit.vala \
	vtgvcsbackendsbzr.vala \
	vtgvcsbackendssvn.vala \
	vtgchangelog.vala \
	vtgparametersdialog.vala \
	vtgconfiguration.vala \
	vtgsourcebookmark.vala \
	vtgsourcebookmarks.vala \
	vtgplugininstance.vala \
	vtgplugin.vala \
	vtgutils.vala \
	$(NULL)

libvtg_la_SOURCES = \
	$(libvtg_la_VALASOURCES:.vala=.c) \
	$(NULL)

libvtg.vala.stamp: $(libvtg_la_VALASOURCES)
	$(VALAC) $(DEBUG) -C --vapidir ../vapi --vapidir ../vsc --vapidir ../vbf --basedir $(top_srcdir)/vtg --pkg config --pkg vbf-1.0 --pkg vsc-1.0 --pkg vala-1.0 --pkg gtksourcecompletion-2.0 --pkg gedit-2.20 --pkg gtk+-2.0 --pkg gtksourceview-2.0 --pkg utils --pkg gdkkeysyms --pkg gconf-2.0 $^
	touch $@

libvtg_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-module -avoid-version

libvtg_la_LIBADD = \
	../vsc/libvsc.la \
	../vbf/libvbf.la \
	$(VTGPLUGIN_LIBS) \
	$(NULL)

libvtg_DATA = \
	vtg.gedit-plugin \
	$(NULL)

EXTRA_DIST = \
	$(libvtg_la_VALASOURCES) \
	libvtg.vala.stamp \
	vtg.gedit-plugin
	$(NULL)

DISTCLEANFILES = \
	$(NULL)

