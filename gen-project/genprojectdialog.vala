/* genprojectdialog.vala
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

class Vala.GenProjectDialog
{
	private Gtk.Dialog config_dialog;
	private Gtk.FileChooserButton project_folder_button;
	private Gtk.ComboBox project_type_combobox;
	private Gtk.ComboBox license_combobox;
	private Gtk.Entry name_entry;
	private Gtk.Entry email_entry;

	private Templates templates;
	
	private void initialize_ui (ProjectOptions options) 
	{
		templates = Templates.load ();
		var builder = new Gtk.Builder ();
		try {
			builder.add_from_file (Path.build_filename (Config.PACKAGE_DATADIR, "ui", "gen-project.ui"));
			config_dialog = builder.get_object ("dialog-gen-project") as Gtk.Dialog;
			assert (config_dialog != null);
			config_dialog.title = _("Vala Project Generator");

			project_folder_button = builder.get_object ("filechooserbutton-project-folder") as Gtk.FileChooserButton;
			assert (project_folder_button != null);

			Gtk.HBox hbox;
			if (options.path != null) {
				hbox = builder.get_object ("hbox-project-folder") as Gtk.HBox;
				assert (hbox != null);
				hbox.visible = false;
			}

			project_type_combobox = builder.get_object ("combobox-project-type") as Gtk.ComboBox; //new Gtk.ComboBox.text ();
			assert (project_type_combobox != null);
			Gtk.CellRenderer renderer = new Gtk.CellRendererPixbuf ();
 			project_type_combobox.pack_start (renderer, false);
			project_type_combobox.add_attribute (renderer, "pixbuf", 2);
			renderer = new Gtk.CellRendererText ();
			project_type_combobox.pack_start (renderer, true);
			project_type_combobox.add_attribute (renderer, "text", 0);
			
			/* Setup project types */
			var model = project_type_combobox.get_model () as Gtk.ListStore;
			assert (model != null);
			int selected_id = 0, count = 0;
			foreach (TemplateDefinition definition in templates.definitions) {
				Gtk.TreeIter item;
				model.append (out item);
				Gdk.Pixbuf icon = null;
				
				if (definition.icon_filename != null) {
					debug ("get icon for %s", definition.icon_filename);
					icon = new Gdk.Pixbuf.from_file_at_size (definition.icon_filename, 24, 24);
				}

				model.set (item, 0, definition.name, 1, definition, 2, icon);
				if (options.template != null && definition.id == options.template.id) {
					selected_id = count;
				}
				count++;
			}
			project_type_combobox.active = selected_id;
			
			license_combobox = builder.get_object ("combobox-project-license") as Gtk.ComboBox;
			assert (license_combobox != null);
			// add the required cell renderer
			renderer = new Gtk.CellRendererText ();
			license_combobox.pack_start (renderer, true);
			license_combobox.add_attribute (renderer, "text", 0);

			model = license_combobox.get_model () as Gtk.ListStore;
			assert (model != null);
			Gtk.TreeIter item;
			model.append (out item);
			model.set (item, 0, _("GNU General Public License, version 2 or later"), 1, ProjectLicense.GPL2);
			model.append (out item);
			model.set (item, 0, _("GNU General Public License, version 3 or later"), 1, ProjectLicense.GPL3);
			model.append (out item);
			model.set (item, 0, _("GNU Lesser General Public License, version 2.1 or later"), 1, ProjectLicense.LGPL2);
			model.append (out item);
			model.set (item, 0, _("GNU Lesser General Public License, version 3 or later"), 1, ProjectLicense.LGPL3);
			license_combobox.active = option_project_license;

			name_entry = builder.get_object ("entry-author-name") as Gtk.Entry;
			assert (name_entry != null);
			if (options.author != null) {
				name_entry.text = options.author;
			}

			email_entry = builder.get_object ("entry-author-email") as Gtk.Entry;
			if (options.email != null) {
				email_entry.text = options.email;
			}
		}
		catch (Error err) {
			error ("can't build dialog ui: %s", err.message);
		}
	}

	public Gtk.ResponseType ask_parameters (ProjectOptions options) 
	{
		Gtk.ResponseType response;

		initialize_ui (options);
		response = (Gtk.ResponseType) config_dialog.run ();
		if (response == Gtk.ResponseType.OK) {
			if (options.path == null)
				options.path = project_folder_button.get_current_folder ();

			options.name = Path.get_basename (options.path);
			options.author = name_entry.text;
			options.email = email_entry.text;
			options.license = (ProjectLicense) license_combobox.active;
			Gtk.TreeIter iter;
			if (project_type_combobox.get_active_iter (out iter)) {
				var model = project_type_combobox.get_model () as Gtk.ListStore;
				TemplateDefinition template = null;
				model.@get (iter, 1, out template);
				options.template = template;
			}
			
		}
		return response;
	}
}

