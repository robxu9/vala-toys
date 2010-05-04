/* valaprojectgenerator.vala
 *
 * Copyright (C) 2007-2010  Jürg Billeter
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Jürg Billeter <j@bitron.ch>
 * 	Andrea Del Signore <sejerpz@tin.it>
 * 	Nicolas Joseph <nicolas.joseph@valaide.org>
 */

using Gtk;

public enum Vala.ProjectType {
	CONSOLE_APPLICATION,
	GTK_APPLICATION
}

public enum Vala.ProjectLicense {
	GPL2,
	GPL3,
	LGPL2,
	LGPL3
}

public class Vala.ProjectOptions {
  public string? path;
  public bool version;
  public string? author;
  public string? email;
  public string? name;
  public string[] files;
  public Vala.ProjectType type;
  public Vala.ProjectLicense license;

  public ProjectOptions () {
    this.type = Vala.ProjectType.GTK_APPLICATION;
    this.license = Vala.ProjectLicense.LGPL2;
	  this.author = Environment.get_variable ("REAL_NAME");
    this.email = Environment.get_variable ("EMAIL_ADDRESS");
  }
}

class Vala.ProjectGenerator : GLib.Object {
	private string namespace_name;
	private string make_name;
	private string upper_case_make_name;

  public ProjectOptions options { get; construct; }

	public ProjectGenerator (ProjectOptions options) {
	  GLib.Object (options: options);
	}

	public void create_project () {
		// only use [a-zA-Z0-9-]* as projectname
		var project_name_str = new StringBuilder ();
		var make_name_str = new StringBuilder ();
		var namespace_name_str = new StringBuilder ();
		for (int i = 0; i < options.name.len (); i++) {
			unichar c = options.name[i];
			if ((c >= 'a' && c <= 'z' ) || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')) {
				project_name_str.append_unichar (c);
				make_name_str.append_unichar (c);
				namespace_name_str.append_unichar (c);
			} else if (c == '-' || c == ' ') {
				project_name_str.append_unichar ('-');
				make_name_str.append_unichar ('_');
			}
		}

		options.name = project_name_str.str;
		namespace_name = namespace_name_str.str.substring (0, 1).up () + namespace_name_str.str.substring (1, namespace_name_str.str.len () - 1);
		make_name = make_name_str.str;
		upper_case_make_name = make_name.up ();

		print (_("creating project %s in %s...\n"), options.name, options.path);
		try {
		  /**
		   * @FIXME Get umask for directory creation
		   */
		  if (!FileUtils.test (options.path, FileTest.EXISTS)) {
			  DirUtils.create_with_parents (options.path, 0777);
		  }
			write_autogen_sh ();
			write_configure_ac ();
			DirUtils.create (options.path + "/src", 0777);
			DirUtils.create (options.path + "/po", 0777);
			write_toplevel_makefile_am ();
			write_src_makefile_am ();
			if (options.type == ProjectType.CONSOLE_APPLICATION) {
				write_main_vala ();
			} else if (options.type == ProjectType.GTK_APPLICATION) {
				write_mainwindow_vala ();
			}
			write_authors ();
			write_maintainers ();
			write_linguas ();
			write_potfiles ();

			FileUtils.set_contents (options.path + "/NEWS", "", -1);
			FileUtils.set_contents (options.path + "/README", "", -1);
			FileUtils.set_contents (options.path + "/ChangeLog", "", -1);
			FileUtils.set_contents (options.path + "/po/ChangeLog", "", -1);

			string s;
			string automake_path = get_automake_path ();
			if (automake_path != null) {
				string install_filename = automake_path + "/INSTALL";
				if (FileUtils.test (install_filename, FileTest.EXISTS)) {
					FileUtils.get_contents (install_filename, out s);
					FileUtils.set_contents (options.path + "/INSTALL", s, -1);
				}
			}

			string license_filename = null;
			if (options.license == ProjectLicense.GPL2) {
				license_filename = Config.PACKAGE_DATADIR + "/licenses/gpl-2.0.txt";
				if (!FileUtils.test (license_filename, FileTest.EXISTS)) {
					license_filename = "/usr/share/common-licenses/GPL-2";
				}
			} else if (options.license == ProjectLicense.LGPL2) {
				license_filename = Config.PACKAGE_DATADIR + "/licenses/lgpl-2.1.txt";
				if (!FileUtils.test (license_filename, FileTest.EXISTS)) {
					license_filename = "/usr/share/common-licenses/LGPL-2.1";
				}
			} else if (options.license == ProjectLicense.GPL3) {
				license_filename = Config.PACKAGE_DATADIR + "/licenses/gpl-3.0.txt";
				if (!FileUtils.test (license_filename, FileTest.EXISTS)) {
					license_filename = "/usr/share/common-licenses/GPL-3";
				}
			} else if (options.license == ProjectLicense.LGPL3) {
				license_filename = Config.PACKAGE_DATADIR + "/licenses/lgpl-3.0.txt";
				if (!FileUtils.test (license_filename, FileTest.EXISTS)) {
					license_filename = "/usr/share/common-licenses/LGPL-3";
				}
			}
			if (license_filename != null && FileUtils.test (license_filename, FileTest.EXISTS)) {
				FileUtils.get_contents (license_filename, out s);
				FileUtils.set_contents (options.path + "/COPYING", s, -1);
			}
		} catch (FileError e) {
			critical ("Error while creating project: %s", e.message);
		}
	}

	private void write_autogen_sh () throws FileError {
		var s = new StringBuilder ();

		s.append ("#!/bin/sh\n");
		s.append ("# Run this to generate all the initial makefiles, etc.\n\n");

		s.append ("srcdir=`dirname $0`\n");
		s.append ("test -z \"$srcdir\" && srcdir=.\n\n");

		s.append_printf ("PKG_NAME=\"%s\"\n\n", options.name);

		s.append (". gnome-autogen.sh\n");

		FileUtils.set_contents (options.path + "/autogen.sh", s.str, -1);
		FileUtils.chmod (options.path + "/autogen.sh", 0755);
	}

	private void write_configure_ac () throws FileError {
		bool use_gtk = (options.type == ProjectType.GTK_APPLICATION);

		var s = new StringBuilder ();

		s.append_printf ("AC_INIT([%s], [0.1.0], [%s], [%s])\n", options.name, options.email, options.name);
		s.append ("AC_CONFIG_SRCDIR([Makefile.am])\n");
		s.append ("AC_CONFIG_HEADERS(config.h)\n");
		s.append ("AM_INIT_AUTOMAKE([dist-bzip2])\n");
		s.append ("AM_MAINTAINER_MODE\n\n");

		s.append ("AC_PROG_CC\n");
		s.append ("AM_PROG_CC_C_O\n");
		s.append ("AC_DISABLE_STATIC\n");
		s.append ("AC_PROG_LIBTOOL\n\n");

		s.append ("AC_PATH_PROG(VALAC, valac, valac)\n");
		s.append ("AC_SUBST(VALAC)\n\n");

		s.append ("AH_TEMPLATE([GETTEXT_PACKAGE], [Package name for gettext])\n");
		s.append_printf ("GETTEXT_PACKAGE=%s\n", options.name);
		s.append ("AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, \"$GETTEXT_PACKAGE\")\n");
		s.append ("AC_SUBST(GETTEXT_PACKAGE)\n");
		s.append ("AM_GLIB_GNU_GETTEXT\n");
		s.append ("IT_PROG_INTLTOOL([0.35.0])\n\n");

		s.append ("AC_SUBST(CFLAGS)\n");
		s.append ("AC_SUBST(CPPFLAGS)\n");
		s.append ("AC_SUBST(LDFLAGS)\n\n");

		s.append ("GLIB_REQUIRED=2.12.0\n");
		if (use_gtk) {
			s.append ("GTK_REQUIRED=2.10.0\n");
		}
		s.append ("\n");

		s.append_printf ("PKG_CHECK_MODULES(%s, glib-2.0 >= $GLIB_REQUIRED gobject-2.0 >= $GLIB_REQUIRED", upper_case_make_name);
		if (use_gtk) {
			s.append (" gtk+-2.0 >= $GTK_REQUIRED");
		}
		s.append (")\n");
		s.append_printf ("AC_SUBST(%s_CFLAGS)\n", upper_case_make_name);
		s.append_printf ("AC_SUBST(%s_LIBS)\n\n", upper_case_make_name);

		s.append ("AC_CONFIG_FILES([Makefile\n");
		s.append ("\tsrc/Makefile\n");
		s.append ("\tpo/Makefile.in])\n\n");

		s.append ("AC_OUTPUT\n");

		FileUtils.set_contents (options.path + "/configure.ac", s.str, -1);
	}

	private void write_toplevel_makefile_am () throws FileError {
		var s = new StringBuilder ();

		s.append ("NULL = \n\n");

		s.append ("#Build in these directories:\n\n");

		s.append ("SUBDIRS = \\\n");
		s.append ("\tsrc \\\n");
		s.append ("\tpo \\\n");
		s.append ("\t$(NULL)\n\n");

		s.append_printf ("%sdocdir = ${prefix}/doc/%s\n", options.name, options.name);
		s.append_printf ("%sdoc_DATA = \\\n", options.name);
		s.append ("\tChangeLog \\\n");
		s.append ("\tREADME \\\n");
		s.append ("\tCOPYING \\\n");
		s.append ("\tAUTHORS \\\n");
		s.append ("\tINSTALL \\\n");
		s.append ("\tNEWS\\\n");
		s.append ("\t$(NULL)\n\n");

		s.append ("EXTRA_DIST = \\\n");
		s.append_printf ("\t$(%sdoc_DATA) \\\n", options.name);
		s.append ("\tintltool-extract.in \\\n");
		s.append ("\tintltool-merge.in \\\n");
		s.append ("\tintltool-update.in\\\n");
		s.append ("\t$(NULL)\n\n");

		s.append ("DISTCLEANFILES = \\\n");
		s.append ("\tintltool-extract \\\n");
		s.append ("\tintltool-merge \\\n");
		s.append ("\tintltool-update \\\n");
		s.append ("\tpo/.intltool-merge-cache \\\n");
		s.append ("\t$(NULL)\n\n");

		FileUtils.set_contents (options.path + "/Makefile.am", s.str, -1);
	}

	private void write_src_makefile_am () throws FileError {
		bool use_gtk = (options.type == ProjectType.GTK_APPLICATION);
		bool am_has_vala_support = get_automake_has_native_vala_support ();

		var s = new StringBuilder ();

		s.append ("NULL = \n\n");

		s.append ("AM_CPPFLAGS = \\\n");
		s.append_printf ("\t$(%s_CFLAGS) \\\n", upper_case_make_name);
		s.append ("\t-include $(CONFIG_HEADER) \\\n");
		s.append ("\t$(NULL)\n\n");

		if (!am_has_vala_support) {
			s.append_printf ("BUILT_SOURCES = %s.vala.stamp\n\n", options.name);
		}

		s.append_printf ("bin_PROGRAMS = %s\n\n", options.name);

		if (am_has_vala_support) {
			s.append_printf ("%s_SOURCES = \\\n", make_name);
		} else {
			s.append_printf ("%s_VALASOURCES = \\\n", make_name);
		}

		if (use_gtk) {
			s.append ("\tmainwindow.vala \\\n");
		} else {
			s.append ("\tmain.vala \\\n");
		}
		s.append ("\t$(NULL)\n\n");

		if (am_has_vala_support) {
			if (use_gtk) {
				s.append_printf ("%s_VALAFLAGS = --pkg gtk+-2.0\n", make_name);
				s.append ("\n");
			}
		} else {
			s.append_printf ("%s_SOURCES = \\\n", make_name);
			s.append_printf ("\t$(%s_VALASOURCES:.vala=.c) \\\n", make_name);
			s.append ("\t$(NULL)\n\n");

			s.append_printf ("%s.vala.stamp: $(%s_VALASOURCES)\n", options.name, make_name);
			s.append ("\t$(VALAC) -C ");
			if (use_gtk) {
				s.append ("--pkg gtk+-2.0 ");
			}
			s.append ("--basedir $(top_srcdir)/src $^\n");
			s.append ("\ttouch $@\n\n");
		}

		s.append_printf ("%s_LDADD = \\\n", make_name);
		s.append_printf ("\t$(%s_LIBS) \\\n", upper_case_make_name);
		s.append ("\t$(NULL)\n\n");

		s.append ("EXTRA_DIST = \\\n");
		if (!am_has_vala_support) {
			s.append_printf ("\t$(%s_VALASOURCES) \\\n", make_name);
			s.append_printf ("\t%s.vala.stamp \\\n", options.name);
		}
		s.append ("\t$(NULL)\n\n");

		s.append ("DISTCLEANFILES = \\\n");
		s.append ("\t$(NULL)\n\n");

		FileUtils.set_contents (options.path + "/src/Makefile.am", s.str, -1);
	}

	private string generate_source_file_header (string filename) {
		var s = new StringBuilder ();

		TimeVal tv = TimeVal ();
		Date d = Date ();
		d.set_time_val (tv);

		s.append_printf ("/* %s\n", filename);
		s.append (" *\n");
		s.append_printf (" * Copyright (C) %d  %s\n", d.get_year (), options.author);
		s.append (" *\n");

		string license_name = "";
		string license_version = null;
		string program_type = null;
		switch (options.license) {
		  case ProjectLicense.GPL2:
			  license_name = "GNU General Public License";
			  license_version = "2";
			  program_type = "program";
			  break;
		  case ProjectLicense.GPL3:
			  license_name = "GNU General Public License";
			  license_version = "3";
			  program_type = "program";
			  break;
		  case ProjectLicense.LGPL2:
			  license_name = "GNU Lesser General Public License";
			  license_version = "2.1";
			  program_type = "library";
			  break;
		  case ProjectLicense.LGPL3:
			  license_name = "GNU Lesser General Public License";
			  license_version = "3";
			  program_type = "library";
			  break;
		}

		s.append_printf (" * This %s is free software: you can redistribute it and/or modify\n", program_type);
		s.append_printf (" * it under the terms of the %s as published by\n", license_name);
		s.append_printf (" * the Free Software Foundation, either version %s of the License, or\n", license_version);
		s.append (" * (at your option) any later version.\n");
		s.append (" *\n");
		s.append_printf (" * This %s is distributed in the hope that it will be useful,\n", program_type);
		s.append (" * but WITHOUT ANY WARRANTY; without even the implied warranty of\n");
		s.append (" * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n");
		s.append_printf (" * %s for more details.\n", license_name);
		s.append (" *\n");
		s.append_printf (" * You should have received a copy of the %s\n", license_name);
		s.append_printf (" * along with this %s.  If not, see <http://www.gnu.org/licenses/>.\n", program_type);

		s.append (" *\n");
		s.append (" * Author:\n");
		s.append_printf (" * \t%s <%s>\n", options.author, options.email);
		s.append (" */\n\n");

		return s.str;
	}

	private void write_main_vala () throws FileError {
		var s = new StringBuilder ();

		s.append (generate_source_file_header ("main.vala"));

		s.append ("using GLib;\n");
		s.append ("\n");

		s.append_printf ("public class %s.Main : Object {\n", namespace_name);
		s.append ("\tpublic Main () {\n");
		s.append ("\t}\n");
		s.append ("\n");
		s.append ("\tpublic void run () {\n");
		s.append ("\t\tstdout.printf (\"Hello, world!\\n\");\n");
		s.append ("\t}\n");
		s.append ("\n");
		s.append ("\tstatic int main (string[] args) {\n");
		s.append ("\t\tvar main = new Main ();\n");
		s.append ("\t\tmain.run ();\n");
		s.append ("\t\treturn 0;\n");
		s.append ("\t}\n");
		s.append ("\n");
		s.append ("}\n");

		FileUtils.set_contents (options.path + "/src/main.vala", s.str, -1);
	}

	private void write_mainwindow_vala () throws FileError {
		var s = new StringBuilder ();

		s.append (generate_source_file_header ("mainwindow.vala"));

		s.append ("using GLib;\n");
		s.append ("using Gtk;\n");
		s.append ("\n");

		s.append_printf ("public class %s.MainWindow : Window {\n", namespace_name);
		s.append ("\tprivate TextBuffer text_buffer;\n");
		s.append ("\tprivate string filename;\n");
		s.append ("\n");
		s.append ("\tpublic MainWindow () {\n");
		s.append_printf ("\t\ttitle = \"%s\";\n", options.name.escape (""));
		s.append ("\t}\n");
		s.append ("\n");
		s.append ("\tconstruct {\n");
		s.append ("\t\tset_default_size (600, 400);\n");
		s.append ("\n");
		s.append ("\t\tdestroy += Gtk.main_quit;\n");
		s.append ("\n");
		s.append ("\t\tvar vbox = new VBox (false, 0);\n");
		s.append ("\t\tadd (vbox);\n");
		s.append ("\t\tvbox.show ();\n");
		s.append ("\n");
		s.append ("\t\tvar toolbar = new Toolbar ();\n");
		s.append ("\t\tvbox.pack_start (toolbar, false, false, 0);\n");
		s.append ("\t\ttoolbar.show ();\n");
		s.append ("\n");
		s.append ("\t\tvar button = new ToolButton.from_stock (Gtk.STOCK_SAVE);\n");
		s.append ("\t\ttoolbar.insert (button, -1);\n");
		s.append ("\t\tbutton.is_important = true;\n");
		s.append ("\t\tbutton.clicked += on_save_clicked;\n");
		s.append ("\t\tbutton.show ();\n");
		s.append ("\n");
		s.append ("\t\tvar scrolled_window = new ScrolledWindow (null, null);\n");
		s.append ("\t\tvbox.pack_start (scrolled_window, true, true, 0);\n");
		s.append ("\t\tscrolled_window.hscrollbar_policy = PolicyType.AUTOMATIC;\n");
		s.append ("\t\tscrolled_window.vscrollbar_policy = PolicyType.AUTOMATIC;\n");
		s.append ("\t\tscrolled_window.show ();\n");
		s.append ("\n");
		s.append ("\t\ttext_buffer = new TextBuffer (null);\n");
		s.append ("\n");
		s.append ("\t\tvar text_view = new TextView.with_buffer (text_buffer);\n");
		s.append ("\t\tscrolled_window.add (text_view);\n");
		s.append ("\t\ttext_view.show ();\n");
		s.append ("\t}\n");
		s.append ("\n");
		s.append ("\tpublic void run () {\n");
		s.append ("\t\tshow ();\n");
		s.append ("\n");
		s.append ("\t\tGtk.main ();\n");
		s.append ("\t}\n");
		s.append ("\n");
		s.append ("\tprivate void on_save_clicked (ToolButton button) {\n");
		s.append ("\t\tif (filename == null) {\n");
		s.append ("\t\t\tvar dialog = new FileChooserDialog (_(\"Save File\"), this, FileChooserAction.SAVE,\n");
		s.append ("\t\t\t\tGtk.STOCK_CANCEL, ResponseType.CANCEL,\n");
		s.append ("\t\t\t\tGtk.STOCK_SAVE, ResponseType.ACCEPT);\n");
		s.append ("\t\t\tdialog.set_do_overwrite_confirmation (true);\n");
		s.append ("\t\t\tif (dialog.run () == ResponseType.ACCEPT) {\n");
		s.append ("\t\t\t\tfilename = dialog.get_filename ();\n");
		s.append ("\t\t\t}\n");
		s.append ("\n");
		s.append ("\t\t\tdialog.destroy ();\n");
		s.append ("\t\t\tif (filename == null) {\n");
		s.append ("\t\t\t\treturn;\n");
		s.append ("\t\t\t}\n");
		s.append ("\t\t}\n");
		s.append ("\n");
		s.append ("\t\ttry {\n");
		s.append ("\t\t\tTextIter start_iter, end_iter;\n");
		s.append ("\t\t\ttext_buffer.get_bounds (out start_iter, out end_iter);\n");
		s.append ("\t\t\tstring text = text_buffer.get_text (start_iter, end_iter, true);\n");
		s.append ("\t\t\tFileUtils.set_contents (filename, text, -1);\n");
		s.append ("\t\t} catch (FileError e) {\n");
		s.append ("\t\t\tcritical (\"Error while trying to save file: %s\", e.message);\n");
		s.append ("\t\t\tfilename = null;\n");
		s.append ("\t\t}\n");
		s.append ("\n");
		s.append ("\t}\n");
		s.append ("\n");
		s.append ("\tstatic int main (string[] args) {\n");
		s.append ("\t\tGtk.init (ref args);\n");
		s.append ("\n");
		s.append ("\t\tvar window = new MainWindow ();\n");
		s.append ("\t\twindow.run ();\n");
		s.append ("\t\treturn 0;\n");
		s.append ("\t}\n");
		s.append ("\n");
		s.append ("}\n");

		FileUtils.set_contents (options.path + "/src/mainwindow.vala", s.str, -1);
	}

	private void write_potfiles () throws FileError {
		bool use_gtk = (options.type == ProjectType.GTK_APPLICATION);

		var s = new StringBuilder ();

		s.append ("[encoding: UTF-8]\n");
		s.append ("# List of source files which contain translatable strings.\n");
		if (use_gtk) {
			s.append ("src/mainwindow.vala\n");
		} else {
			s.append ("src/main.vala\n");
		}

		FileUtils.set_contents (options.path + "/po/POTFILES.in", s.str, -1);

		if (use_gtk) {
			FileUtils.set_contents (options.path + "/po/POTFILES.skip", "src/mainwindow.c\n", -1);
		} else {
			FileUtils.set_contents (options.path + "/po/POTFILES.skip", "src/main.c\n", -1);
		}
	}

	private void write_linguas () throws FileError {
		string s = "# please keep this list sorted alphabetically\n#\n";

		FileUtils.set_contents (options.path + "/po/LINGUAS", s, -1);
	}

	private void write_authors () throws FileError {
		string s = "%s <%s>\n".printf (options.author, options.email);

		FileUtils.set_contents (options.path + "/AUTHORS", s, -1);
	}

	private void write_maintainers () throws FileError {
		string s = "%s\nE-mail: %s\n".printf (options.author, options.email);

		FileUtils.set_contents (options.path + "/MAINTAINERS", s, -1);
	}

	private string? get_automake_path () {
		var automake_paths = new string[] { "/usr/share/automake",
		                                    "/usr/share/automake-1.10",
		                                    "/usr/share/automake-1.9" };

		foreach (string automake_path in automake_paths) {
			if (FileUtils.test (automake_path, FileTest.IS_DIR)) {
				return automake_path;
			}
		}

		return null;
	}

	private bool get_automake_has_native_vala_support ()
	{
		bool res = false;
		try {
			string am_output;
			Process.spawn_command_line_sync ("automake --version", out am_output);
			//version example: automake (GNU automake) 1.10.2
			if (am_output != null)
			{
				string first_line = am_output.split ("\n", 2)[0];
				string[] tmps = first_line.split(" ");
				if (tmps.length > 0)
				{
					string ver = tmps[tmps.length - 1];
					tmps = ver.split(".");
					if (tmps.length >= 2 && tmps[0].to_int() >= 1 && tmps[1].to_int() >= 11) {
						res = true;

					}
				}
			}
		} catch (Error err) {
			warning ("Cannot spawn automake: %s. Native vala support test failed.", err.message);
		}
		return res;
	}
}

