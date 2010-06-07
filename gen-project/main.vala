/* valaprojectgenerator.vala
 *
 * Copyright (C) 2010  Jürg Billeter
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

using GenProject;

string option_project_path;
bool option_version;
bool option_list_templates;
int option_template_id = 0;
string option_author;
string option_email;
[NoArrayLength ()]
string[] option_files;
ProjectLicense option_project_license;

const OptionEntry[] options = {
	{ "projectdir", 'p', 0, OptionArg.FILENAME, ref option_project_path, "Project directory", "DIRECTORY" },
	{ "template-id", 't', 0, OptionArg.INT, ref option_template_id, "Project TYPE id. See --list-templates for a list of avalable templates", "TYPE" },
	{ "list-templates", 0, 0, OptionArg.NONE, ref option_list_templates, "Print a list of avalable project templates", null },
	{ "license", 'l', 0, OptionArg.CALLBACK, (void *) option_parse_callback, "License TYPE: gpl2, gpl3, lgpl2, lgpl3", "TYPE" },
	{ "version", 0, 0, OptionArg.NONE, ref option_version, "Display version number", null },
	{ "author", 'a', 0, OptionArg.STRING, ref option_author, "Author name", "NAME" },
	{ "email", 'e', 0, OptionArg.STRING, ref option_email, "Author email address", "EMAIL" },
	{ "", 0, 0, OptionArg.FILENAME_ARRAY, ref option_files, "Project NAME", "NAME" },
	{ null }
};

bool option_parse_callback (string option_name, string @value,  void *data) throws OptionError
{
	if (option_name == "--license"  || option_name == "-l") {
		if (@value == "gpl2")
			option_project_license = ProjectLicense.GPL2;
		else if (@value == "gpl3")
			option_project_license = ProjectLicense.GPL3;
		else if (@value == "lgpl2")
			option_project_license = ProjectLicense.LGPL2;
		else if (@value == "lgpl3")
			option_project_license = ProjectLicense.LGPL3;
		else
			throw new OptionError.BAD_VALUE (_("license of type %s is not available").printf (@value));
	} else {
		throw new OptionError.UNKNOWN_OPTION (_("unknown option %s").printf (option_name));
	}
	return true;
}

int main (string[] args)
{
	ProjectOptions project_options = null;

	Gtk.init (ref args);
	Intl.bindtextdomain (Config.GETTEXT_PACKAGE, null);

	try {
		project_options = new ProjectOptions ();
		var opt_context = new OptionContext ("- Vala Project Generator");
		opt_context.set_help_enabled (true);
		opt_context.add_main_entries (options, null);
		opt_context.parse (ref args);

		project_options.version = option_version;
		if (option_author != null)
			project_options.author = option_author;
		if (option_email != null)
			project_options.email = option_email;
		if (option_project_license != 0)
			project_options.license = option_project_license;
		if (option_project_path != null)
			project_options.path = option_project_path;

		if (option_files != null) {
			if (option_files[1] != null) {
				//more then a project name
				throw new OptionError.BAD_VALUE (_("Just a single project name can be specified on the command line"));
			}
			project_options.name = option_files[0];
			if (option_project_path == null) {
				//default to current directory in not specified with -p
				project_options.path = Environment.get_current_dir ();
			}
		}
	} catch (OptionError e) {
		stdout.printf ("%s\n", e.message);
		stdout.printf (_("Run '%s --help' to see a full list of available command line options.\n"), args[0]);
		return 1;
	}

	if (option_version) {
		stdout.printf ("vala-gen-project %s\n", Config.PACKAGE_VERSION);
		return 0;
	}

	if (option_list_templates) {
		var templates = Templates.load ();
		stdout.printf (_("Available project templates\n"));
		foreach (var definition in templates.definitions) {
			stdout.printf (_("\tname '%s' - id %d\n").printf (definition.name, definition.id + 1));
		}
		return 0;
	}
	
	if (option_template_id > 0) {
		var templates = Templates.load ();
		project_options.template = null;
		foreach (var definition in templates.definitions) {
			if (definition.id + 1 == option_template_id) {
				project_options.template = definition;
				break;
			}
		}
		if (project_options.template == null) {
			stdout.printf (_("Cannot find template id %d\n"), option_template_id);
			stdout.printf (_("Run '%s --list-templates' to see a full list of available templates.\n"), args[0]);
			return 1;
		}
	}
	
	var dialog = new Vala.GenProjectDialog ();
	if (project_options.name != null || dialog.ask_parameters (project_options) == Gtk.ResponseType.OK) {
		var generator = new ProjectGenerator (project_options);
		generator.create_project ();
		return 0;
	}
	return 1;
}

