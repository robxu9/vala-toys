NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(VTG_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	-I $(top_srcdir)/vsc/ \
	$(NULL)

BUILT_SOURCES = vsc-shell.vala.stamp


if ENABLE_DEBUG
        DEBUG = -g
else
        DEBUG = -Xcc "-D G_DISABLE_DEBUG"
endif

bin_PROGRAMS = vsc-shell

vsc_shell_VALASOURCES = \
	vsccompletionshell.vala \
	$(NULL)


vsc_shell_SOURCES = \
	$(vsc_shell_VALASOURCES:.vala=.c) \
	$(vsc_shell_VALASOURCES:.vala=.h) \
	$(NULL)

vsc-shell.vala.stamp: $(vsc_shell_VALASOURCES)
	$(VALAC) $(DEBUG) --thread -C --vapidir ../vapi --vapidir ../vsc --pkg vsc-1.0 --pkg config --pkg vala-1.0 --pkg utils --pkg vala-1.0 --pkg gtk+-2.0 --pkg readline $^
	touch $@

vsc_shell_LDADD = \
	../vsc/libvsc.la \
	$(VTG_LIBS) \
	$(NULL)

EXTRA_DIST = \
	$(vsc_shell_VALASOURCES) \
	vsc-shell.vala.stamp \
	$(NULL)

DISTCLEANFILES = \
	$(NULL)
