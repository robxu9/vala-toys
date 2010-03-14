NULL =

SUBDIRS = ui licenses

#VALAC = valac

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(GENPROJECT_CFLAGS) \
	-include config.h \
	-DPACKAGE_DATADIR=\"$(pkgdatadir)\" \
	$(NULL)

BUILT_SOURCES = vala-gen-project.vala.stamp

bin_PROGRAMS = \
	vala-gen-project \
	$(NULL)

vala_gen_project_VALASOURCES = \
	valaprojectgenerator.vala \
	$(NULL)

vala_gen_project_SOURCES = \
	vala-gen-project.vala.stamp \
	$(vala_gen_project_VALASOURCES:.vala=.c) \
	$(vala_gen_project_VALASOURCES:.vala=.h) \
	$(NULL)

vala-gen-project.vala.stamp: $(vala_gen_project_VALASOURCES)
	$(VALAC) -C --vapidir $(srcdir)/../vapi --pkg config --pkg gtk+-2.0 --basedir $(top_srcdir) $^
	touch $@

vala_gen_project_LDADD = \
	$(GENPROJECT_LIBS) \
	$(NULL)

EXTRA_DIST = $(vala_gen_project_VALASOURCES) vala-gen-project.vala.stamp
