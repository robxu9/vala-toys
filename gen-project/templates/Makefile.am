NULL =

TEMPLATES = \
	console-vala-template \
	$(NULL)

BUILT_SOURCES = templates.stamp

templatesdir = $(pkgdatadir)/templates

# the created tar archive can be extracted with: tar --strip-components=1 -zxvf tar-archive.tar.gz

templates.stamp: $(TEMPLATES)
	tar zcvf console-vala-template.tar.gz console-vala-template
	touch $@

dist_templates_DATA = \
	console-vala-template.ini \
	console-vala-template.png \
	console-vala-template.tar.gz \
	$(NULL)

