NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	../vsc \
	$(NULL)

AM_CPPFLAGS = \
	$(VTG_CFLAGS) \
	-DPACKAGE_DATA_DIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = vsc-shell.vala.stamp


if ENABLE_DEBUG
        DEBUG = -g
else
        DEBUG = -D G_DISABLE_DEBUG
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
	$(VALAC) $(DEBUG) --thread -C  --vapidir ./vtg --vapidir ../vapi --vapidir ../vsc --pkg vsc-1.0 --pkg config --pkg vala-1.0 --pkg utils --pkg vala-1.0 --pkg gtk+-2.0 --basedir $(top_srcdir) $^
	touch $@

vsc_shell_LDADD = \
	../vsc/libvsc.la \
	$(VTG_LIBS) \
	$(NULL)

EXTRA_DIST = \
	intltool-extract.in \
	intltool-update.in \
	intltool-merge.in \
	$(vsc_shell_VALASOURCES) \
	vsc-shell.vala.stamp \
	$(NULL)

DISTCLEANFILES = \
	intltool-extract \
	intltool-update \
	intltool-merge \
	po/.intltool-merge-cache \
	$(NULL)
