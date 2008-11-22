## Process this file with automake to produce Makefile.in

uidir = $(datadir)/vtg/ui

ui_DATA = vtg-config-dialog.ui vtg.ui

#BUILT_SOURCES = tuntun.ui.stamp

GLADE_FILES = vtg.glade

$(ui_DATA): $(GLADE_FILES)
	gtk-builder-convert $^ `basename $^ .glade`.ui.tmp
	sed -e "/.*requires-version.*/d"  vtg.ui.tmp > vtg.ui
	rm `basename $^ .glade`.ui.tmp

EXTRA_DIST = $(ui_DATA) \
	vtg.glade

CLEANFILES = $(ui_DATA) 
