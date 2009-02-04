NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(VSC_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = libvbf.vala.stamp vbftest.vala.stamp

if ENABLE_DEBUG
        DEBUG = --Xcc "-g" --Xcc "-O0"
else
        DEBUG = --Xcc "-D G_DISABLE_DEBUG"
endif

noinst_PROGRAMS = vbftest

noinst_LTLIBRARIES = libvbf.la

vbftest_VALASOURCES = \
	vbftest.vala \
	$(NULL)

libvbf_la_VALASOURCES = \
	vbfproject.vala \
	vbfgroup.vala \
	vbfmodule.vala \
	vbftarget.vala \
	vbfsource.vala \
	vbffile.vala \
	vbfpackage.vala \
	vbfvariable.vala \
	vbfstringliteral.vala \
	vbfiprojectmanager.vala \
	vbfmanager.vala \
	vbfconfignode.vala \
	vbfconfignodepair.vala \
	vbfconfignodelist.vala \
	vbfunresolvedconfignode.vala \
	am/vbfamprojectmanager.vala \
	$(NULL)

vbftest_SOURCES = \
	$(vbftest_VALASOURCES:.vala=.c) \
	$(vbftest_VALASOURCES:.vala=.h) \
	$(NULL)

libvbf_la_SOURCES = \
	$(libvbf_la_VALASOURCES:.vala=.c) \
	$(libvbf_la_VALASOURCES:.vala=.h) \
	$(NULL)

vbftest.vala.stamp: $(vbftest_VALASOURCES)
	$(VALAC) $(DEBUG) -C  --vapidir ../vapi --pkg config --pkg vala-1.0 --pkg utils vbf-1.0.vapi $^
	touch $@

libvbf.vala.stamp: $(libvbf_la_VALASOURCES)
	$(VALAC) $(DEBUG) -C  --library vbf-1.0 --vapidir ../vapi --pkg gio-2.0 --pkg config --pkg vala-1.0 --pkg utils --basedir $(top_srcdir)/vbf $^
	touch $@

libvbf_la_LDFLAGS = \
	-static \
	$(NULL)

libvbf_la_LIBADD = \
	$(VSC_LIBS) \
	$(NULL)

vbftest_LDADD = \
	$(VSC_LIBS) \
	libvbf.la  \
	$(NULL)

EXTRA_DIST = \
	$(libvbf_la_VALASOURCES) \
	libvbf.vala.stamp \
	$(NULL)

DISTCLEANFILES = \
	$(NULL)
