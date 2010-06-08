NULL =

EXTRA_DIST = \
	console-vala-template \
	gtk+-vala-template \
	$(NULL)

TEMPLATES = \
	console-vala-template/AUTHORS.template \
	console-vala-template/MAINTAINERS.template \
	console-vala-template/Makefile.am.template \
	console-vala-template/configure.ac.template \
	console-vala-template/autogen.sh.template \
	console-vala-template/ChangeLog \
	console-vala-template/NEWS \
	console-vala-template/README \
	console-vala-template/src/main.vala.template \
	console-vala-template/src/Makefile.am.template \
	console-vala-template/po/ChangeLog \
	console-vala-template/po/LINGUAS \
	console-vala-template/po/POTFILES.in \
	console-vala-template/po/POTFILES.skip \
	gtk+-vala-template/configure.ac.template \
	gtk+-vala-template/AUTHORS.template \
	gtk+-vala-template/autogen.sh.template \
	gtk+-vala-template/ChangeLog \
	gtk+-vala-template/MAINTAINERS.template \
	gtk+-vala-template/Makefile.am.template \
	gtk+-vala-template/NEWS \
	gtk+-vala-template/README \
	gtk+-vala-template/src/Makefile.am.template \
	gtk+-vala-template/src/main.vala.template \
	gtk+-vala-template/po/ChangeLog \
	gtk+-vala-template/po/LINGUAS \
	gtk+-vala-template/po/POTFILES.in \
	gtk+-vala-template/po/POTFILES.skip \
	$(NULL)

BUILT_SOURCES = templates.stamp

templatesdir = $(pkgdatadir)/templates

# the created tar archive can be extracted with: tar --strip-components=1 -zxvf tar-archive.tar.gz

templates.stamp: $(TEMPLATES)
	tar zcvf console-vala-template.tar.gz $(srcdir)/console-vala-template
	tar zcvf gtk+-vala-template.tar.gz $(srcdir)/gtk+-vala-template
	touch $@

dist_templates_DATA = \
	console-vala-template.ini \
	console-vala-template.png \
	console-vala-template.tar.gz \
	gtk+-vala-template.ini \
	gtk+-vala-template.png \
	gtk+-vala-tamplate.tar.gz \
	$(NULL)

DISTCLEANFILES = \
	templates.stamp \
	console-vala-template.tar.gz \
	gtk+-vala-template.tar.gz \
	$(NULL)

