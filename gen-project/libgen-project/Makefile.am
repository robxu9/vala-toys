NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(GENPROJECT_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	$(NULL)

noinst_LTLIBRARIES = libgen-project.la

libgen_project_la_VALAFLAGS = -C -H gen-project.h --library gen-project-1.0 --vapidir $(top_srcdir)/vapi --pkg gio-2.0 --pkg config --pkg vala-$(VALA_VERSION) --pkg utils 

#--basedir $(top_srcdir)/gen-project/libgen-project 

libgen_project_la_SOURCES = \
	projectgenerator.vala \
	projectoptions.vala \
	templatedefinition.vala \
	templates.vala \
	constants.vala \
	$(NULL)


libgen_projectincludedir = $(includedir)/gen-project-1.0

libgen_projectinclude_HEADERS = \
	gen-project.h \
	$(NULL)

libgen_project_la_LDFLAGS = \
	-version-info 0:1:0 \
	$(NULL)

libgen_project_la_LIBADD = \
	$(GENPROJECT_LIBS) \
	$(NULL)


EXTRA_DIST = \
	$(NULL)

DISTCLEANFILES = \
	$(NULL)

MAINTAINERCLEANFILES = \
	gen-project-1.0.vapi \
	gen-project.h \
	$(NULL)


