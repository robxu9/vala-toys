NULL=

gsettings_SCHEMAS = org.gnome.gedit.plugins.vala-toys.gschema.xml

@INTLTOOL_XML_NOMERGE_RULE@

@GSETTINGS_RULES@

convertdir = $(datadir)/GConf/gsettings
convert_DATA = vala-toys.convert

EXTRA_DIST = \
	org.gnome.gedit.plugins.vala-toys.gschema.xml.in.in \
	vala-toys.convert \
	$(NULL)

CLEANFILES = \
	$(gsettings_SCHEMAS) \
	$(NULL)

DISTCLEANFILES = \
	$(gsettings_SCHEMAS) \
	$(NULL)

