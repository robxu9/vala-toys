NULL =

templatesdir = $(pkgdatadir)/templates

# the created tar archive will be extracted with by the vala-gen-project executable: tar -zxvf tar-archive.tar.gz

TEMPLATES = \
	console-vala.template \
	gtk+-2.0-vala.template \
	gtk+-2.0-genie.template \
	sharedlib-vala.template \
	gedit-2.20-plugin.template \
	gedit-3.0-plugin.template \
	$(NULL)

BUILT_SOURCES = templates.stamp \
	$(NULL)

TEMPLATES_DIRS = \
	$(TEMPLATES:.template=) \
	$(NULL)

templates.stamp: $(TEMPLATES_DIRS)
	for TEMPLATE in $(TEMPLATES_DIRS); do \
		cp $(srcdir)/$$TEMPLATE/$$TEMPLATE.ini $(builddir); \
		cp $(srcdir)/$$TEMPLATE/$$TEMPLATE.png $(builddir); \
		tar -zc -C $(srcdir)/$$TEMPLATE/template/ -f $(builddir)/$$TEMPLATE.tar.gz .; \
	done; \
	touch $@

nodist_templates_DATA = \
	templates.stamp \  
        $(TEMPLATES:.template=.ini) \
        $(TEMPLATES:.template=.png) \
        $(TEMPLATES:.template=.tar.gz) \
	$(NULL)
 
CLEANFILES = \
	templates.stamp \  
	$(TEMPLATES:.template=.ini) \
	$(TEMPLATES:.template=.png) \
	$(TEMPLATES:.template=.tar.gz) \
	$(NULL)

DISTCLEANFILES = \
	$(CLEANFILES) \
	$(NULL)

EXTRA_DIST = \
	$(TEMPLATES_DIRS) \
	$(NULL)
