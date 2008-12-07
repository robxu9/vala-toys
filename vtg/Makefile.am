NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(VTG_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	-I $(top_srcdir)/vsc \
	$(NULL)

BUILT_SOURCES = libvtg.vala.stamp

if ENABLE_DEBUG
	DEBUG = -g
else
	DEBUG = -D G_DISABLE_DEBUG
endif

libvtgdir = $(libdir)/gedit-2/plugins

libvtg_LTLIBRARIES = libvtg.la


libvtg_la_VALASOURCES = \
	vtgbracketcompletion.vala \
	vtgsymbolcompletionprovider.vala \
	vtgsymbolcompletiontrigger.vala \
	vtgsymbolcompletionhelper.vala \
	vtgprojectmanager.vala \
	vtgprojectmanagerview.vala \
	vtgprojectmanagerbuilder.vala \
	vtgprojectmanagerexecuter.vala \
	vtgprojectmanageroutputview.vala \
	vtgprojectmanagerprocesswatchinfo.vala \
	vtgprojectmanagerbuildlogview.vala \
	vtgprojectmanagerproject.vala \
	vtgprojectmanagerprojectmodule.vala \
	vtgprojectmanagerprojectpackage.vala \
	vtgprojectmanagerprojectgroup.vala \
	vtgprojectmanagerprojecttarget.vala \
	vtgprojectmanagerprojectsource.vala \
	vtgprojectmanagerpackagesdialog.vala \
	vtgprojectmanagerfilteredlistdialog.vala \
	vtgconfiguration.vala \
	vtgplugin.vala \
	vtgutils.vala \
	$(NULL)


libvtg_la_SOURCES = \
	$(libvtg_la_VALASOURCES:.vala=.c) \
	$(libvtg_la_VALASOURCES:.vala=.h) \
	$(NULL)

libvtg.vala.stamp: $(libvtg_la_VALASOURCES)
	$(VALAC) $(DEBUG) -C  --vapidir ../vapi --vapidir ../vsc --pkg config --pkg vsc-1.0 --pkg vala-1.0 --pkg gtksourcecompletion-1.0 --pkg gedit-2.20 --pkg gtk+-2.0 --pkg gtksourceview-2.0 --pkg utils --pkg gdkkeysyms --pkg gnome-build-1.0 --pkg gconf-2.0 $^
	touch $@

libvtg_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-module -avoid-version

libvtg_la_LIBADD = \
	../vsc/libvsc.la \
	$(VTG_LIBS) \
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

