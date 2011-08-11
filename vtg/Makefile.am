NULL = 

AUTOMAKE_OPTIONS = subdir-objects

############################################
# Built utility libraries that vtg links to
############################################
VTGUTILITYLIBS_CPPFLAGS= \
	-I $(top_srcdir)/vbf \
	$(NULL)

VTGUTILITYLIBS_LIBS = \
	../vbf/libvbf.la \
	$(NULL)

VTGUTILITYLIBS_VALAFLAGS = \
	$(NULL)

if !WITH_SYSTEMLIBS
VTGUTILITYLIBS_CPPFLAGS += -I $(top_srcdir)/afrodite
VTGUTILITYLIBS_LIBS += ../afrodite/libafrodite@PACKAGE_SUFFIX@.la 
VTGUTILITYLIBS_VALAFLAGS += --vapidir ../afrodite 
endif
############################################

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(VTGPLUGIN_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	$(VTGUTILITYLIBS_CPPFLAGS) \
	$(NULL)

BUILT_SOURCES = libvtg_la.vala.stamp

if ENABLE_DEBUG
        DEBUG_FLAGS = -g -D DEBUG
endif


libvtgdir = $(datadir)/gedit/plugins

libvtg_LTLIBRARIES = libvtg.la


libvtg_la_VALASOURCES = \
	vtgbracketcompletion.vala \
	vtgsymbolcompletion.vala \
	vtgsymbolcompletionprovider.vala \
	vtgprojectmanagerui.vala \
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
	vtgprojects.vala \
	vtgfilteredlistdialog.vala \
	vtgvcsbackendsvcsbase.vala \
	vtgvcsbackendsitem.vala \
	vtgvcsbackendsgit.vala \
	vtgvcsbackendsbzr.vala \
	vtgvcsbackendssvn.vala \
	vtgchangelog.vala \
	vtgparametersdialog.vala \
	vtgconfiguration.vala \
	vtgsourcebookmark.vala \
	vtgsourcebookmarks.vala \
	vtgplugininstance.vala \
	vtgsourceoutlinerview.vala \
	vtgsourceoutliner.vala \
	vtgplugin.vala \
	vtgutils.vala \
	$(NULL)

libvtg_la_SOURCES = \
	$(libvtg_la_VALASOURCES:.vala=.c) \
	$(NULL)

libvtg_la.vala.stamp: $(libvtg_la_VALASOURCES)
	$(VALAC) $(DEBUG_FLAGS) -C $(VTGUTILITYLIBS_VALAFLAGS) --vapidir ../vapi --vapidir ../vbf --basedir $(top_srcdir)/vtg --pkg config --pkg vbf-1.0 --pkg afrodite@PACKAGE_SUFFIX@ --pkg libvala-$(VALA_VERSION) --pkg gedit-3.0 --pkg gtk+-3.0 --pkg gtksourceview-3.0 --pkg PeasGtk-1.0 --pkg utils --pkg gdkkeysyms $^
	touch $@

libvtg_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-module -avoid-version

libvtg_la_LIBADD = \
	$(VTGUTILITYLIBS_LIBS) \
	$(VTGPLUGIN_LIBS) \
	$(NULL)

libvtg_DATA = \
	vtg.plugin \
	$(NULL)

EXTRA_DIST = \
	$(libvtg_la_VALASOURCES) \
	libvtg_la.vala.stamp \
	vtg.plugin
	$(NULL)

DISTCLEANFILES = \
	$(NULL)

