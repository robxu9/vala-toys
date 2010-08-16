NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(AFRODITE_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = libvbf.vala.stamp vbftest.vala.stamp

if ENABLE_DEBUG
        DEBUG_FLAGS = -g -D DEBUG
endif

noinst_LTLIBRARIES = libvbf.la

noinst_PROGRAMS = vbftest

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
	vbfiprojectbackend.vala \
	vbfmanager.vala \
	vbfconfignode.vala \
	vbfconfignodepair.vala \
	vbfconfignodelist.vala \
	vbfunresolvedconfignode.vala \
	vbfutils.vala \
	backends/vbfautotools.vala \
	$(NULL)

vbftest_SOURCES = \
	$(vbftest_VALASOURCES:.vala=.c) \
	$(NULL)

noinst_HEADERS = \
	vbf.h \
	$(NULL)

libvbf_la_SOURCES = \
	libvbf.vala.stamp \
	vbftest.vala.stamp \
	$(libvbf_la_VALASOURCES:.vala=.c) \
	$(NULL)

libvbf.vala.stamp: $(libvbf_la_VALASOURCES)
	$(VALAC) $(DEBUG_FLAGS) -C -H vbf.h --library vbf-1.0 --vapidir ../vapi --pkg gio-2.0 --pkg config --pkg vala-$(VALA_VERSION) --pkg utils --basedir $(top_srcdir)/vbf $^
	touch $@

vbftest.vala.stamp: $(vbftest_VALASOURCES)
	$(VALAC) $(DEBUG_FLAGS) -C  --vapidir $(srcdir)/../vapi --vapidir $(srcdir) --pkg vala-$(VALA_VERSION) --pkg vbf-1.0 $^
	touch $@

libvbf_la_LDFLAGS = \
	-static \
	$(NULL)

libvbf_la_LIBADD = \
	$(AFRODITE_LIBS) \
	$(NULL)

vbftest_LDADD = \
	$(AFRODITE_LIBS) \
	libvbf.la  \
	$(NULL)

EXTRA_DIST = \
	$(libvbf_la_VALASOURCES) \
	$(vbftest_VALASOURCES) \
	libvbf.vala.stamp \
	vbftest.vala.stamp \
	$(NULL)

DISTCLEANFILES = \
	$(NULL)

