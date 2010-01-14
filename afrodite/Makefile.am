NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(AFRODITE_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = libafrodite.vala.stamp

if ENABLE_DEBUG
        DEBUG = --Xcc "-g" --Xcc "-O0"
else
        DEBUG = --Xcc "-D G_DISABLE_DEBUG"
endif

lib_LTLIBRARIES = libafrodite.la

libafrodite_la_VALASOURCES = \
	astmerger.vala \
	astdumper.vala \
	parser.vala \
	symbol.vala \
	symbolresolver.vala \
	datatype.vala \
	voidtype.vala \
	sourcereference.vala \
	sourcefile.vala \
	ast.vala \
	utils.vala \
	completionengine.vala \
	ellipsistype.vala \
	queryoptions.vala \
	queryresult.vala \
	resultitem.vala \
	constants.vala \
	sourceitem.vala \
	$(NULL)


libafroditeincludedir = $(includedir)/afrodite-1.0

libafroditeinclude_HEADERS = \
	afrodite.h \
	$(NULL)


libafrodite_la_SOURCES = \
	libafrodite.vala.stamp \
	$(libafrodite_la_VALASOURCES:.vala=.c) \
	$(NULL)

libafrodite.vala.stamp: $(libafrodite_la_VALASOURCES)
	$(VALAC) $(DEBUG) -C -H afrodite.h --library afrodite-1.0 --vapidir ../vapi --pkg gio-2.0 --pkg config --pkg vala-1.0 --pkg utils --basedir $(top_srcdir)/afrodite $^
	touch $@

libafrodite_la_LDFLAGS = \
	-version-info 0:1:0 \
	$(NULL)

libafrodite_la_LIBADD = \
	$(AFRODITE_LIBS) \
	$(NULL)


EXTRA_DIST = \
	$(libafrodite_la_VALASOURCES) \
	libafrodite.vala.stamp \
	$(NULL)

DISTCLEANFILES = \
	$(NULL)

MAINTAINERCLEANFILES = \
	afrodite-1.0.vapi \
	afrodite.h \
	$(libafrodite_la_VALASOURCES:.vala=.c) \
	$(NULL)

