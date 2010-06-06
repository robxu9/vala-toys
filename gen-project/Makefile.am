NULL =

SUBDIRS = libgen-project ui licenses templates

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	-I$(top_srcdir)/gen-project/libgen-project \
	$(GENPROJECT_CFLAGS) \
	-include config.h \
	-DPACKAGE_DATADIR=\"$(pkgdatadir)\" \
	$(NULL)

bin_PROGRAMS = \
	vala-gen-project \
	$(NULL)

vala_gen_project_SOURCES = \
	main.vala \
	genprojectdialog.vala \
	$(NULL)

vala_gen_project_VALAFLAGS = --vapidir $(srcdir)/../vapi --vapidir $(srcdir)/libgen-project --pkg gen-project-1.0 --pkg config --pkg gtk+-2.0 --basedir $(top_srcdir) 

vala_gen_project_LDADD = \
	./libgen-project/libgen-project.la
	$(GENPROJECT_LIBS) \
	$(NULL)

EXTRA_DIST = \
	$(NULL)

