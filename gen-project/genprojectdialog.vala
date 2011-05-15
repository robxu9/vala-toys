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
	private Gtk.IconView project_type_iconview;
	private Gtk.ComboBox license_combobox;
	private Gtk.ComboBox combobox_languages;
	private Gtk.Entry name_entry;
	private Gtk.Entry email_entry;
	private Gtk.Button button_create_project;
	private Vala.TagCloud tag_cloud;
	private Templates templates;
	
	private void initialize_ui (ProjectOptions options) 
	{
		Gtk.TreeIter item;
		templates = Templates.load ();
		var builder = new Gtk.Builder ();
		try {
			builder.add_from_file (Path.build_filename (Config.PACKAGE_DATADIR, "ui", "gen-project.ui"));
			config_dialog = builder.get_object ("dialog-gen-project") as Gtk.Dialog;
			assert (config_dialog != null);
			config_dialog.title = _("Vala Project Generator");

			button_create_project = builder.get_object ("button-create-project") as Gtk.Button;
			assert (button_create_project != null);
			
			project_folder_button = builder.get_object ("filechooserbutton-project-folder") as Gtk.FileChooserButton;
			assert (project_folder_button != null);

			Gtk.HBox hbox;
			if (options.path != null) {
				hbox = builder.get_object ("hbox-project-folder") as Gtk.HBox;
				assert (hbox != null);
				hbox.visible = false;
			}

			Gtk.CellRenderer renderer = new Gtk.CellRendererPixbuf ();
			
			project_type_iconview = builder.get_object ("iconview-project-type") as Gtk.IconView;
			assert (project_type_iconview != null);
 			project_type_iconview.pack_start (renderer, false);
			project_type_iconview.add_attribute (renderer, "pixbuf", 2);
			renderer = new Gtk.CellRendererText ();
			project_type_iconview.pack_start (renderer, true);
			project_type_iconview.add_attribute (renderer, "text", 0);
			project_type_iconview.item_activated.connect ((sender) => {
				if (project_type_iconview.get_selected_items ().length () > 0) {
					button_create_project.set_sensitive (true);
				} else {
					button_create_project.set_sensitive (false);
				}
			});
			
			var tags = builder.get_object ("scrolledwindow-tags") as Gtk.ScrolledWindow;
			assert (tags != null);
			tag_cloud = new TagCloud ();
			tag_cloud.selected_items_changed.connect((sender) => {
				// refilter
				refilter_projects ();
			});
			tag_cloud.show_all ();
			tags.add_with_viewport (tag_cloud);
			
			/* Setup project types */
			combobox_languages = builder.get_object ("combobox-project-language") as Gtk.ComboBox;
			assert (combobox_languages != null);
			combobox_languages.changed.connect ((sender) => {
				refilter_projects ();
			});
			var languages_model = combobox_languages.get_model () as Gtk.ListStore;
			renderer = new Gtk.CellRendererText ();
			combobox_languages.pack_start (renderer, true);
			combobox_languages.add_attribute (renderer, "text", 0);

			var model = project_type_iconview.get_model () as Gtk.ListStore;
			assert (model != null);
			int selected_id = 0, count = 0;
			foreach (TemplateDefinition definition in templates.definitions) {
				model.append (out item);
				Gdk.Pixbuf icon = null;
				
				if (definition.icon_filename != null) {
					icon = new Gdk.Pixbuf.from_file_at_size (definition.icon_filename, 24, 24);
				}

				model.set (item, 0, definition.name, 1, definition, 2, icon);
				if (options.template != null && definition.id == options.template.id) {
					selected_id = count;
				}
				
				// add a tag item for each category
				foreach (string tag in definition.tags) {
					var tag_item = tag_cloud.get_item_with_text (tag);
					if (tag_item == null) {
						// if not exists create a new tag item
						tag_item = new TagCloudItem (tag, 0, SelectStatus.SELECTED);
						tag_cloud.add_item (tag_item);
					}
					tag_item.occourrences++;
				}

				// add a tag item for the language
				bool language_exists = false;
				Gtk.TreeIter iter;
				if (languages_model.get_iter_first (out iter)) {
					do {
						string language;
						languages_model.get (iter, 0, out language);
						if (language == definition.language) {
							language_exists = true;
							break;
						}
					} while (languages_model.iter_next (ref iter));
				}
				if (!language_exists) {
					languages_model.append (out item);
					languages_model.set (item, 0, definition.language);
				}
				count++;
			}
			
			combobox_languages.set_active (0);
			
			var filtered_model = new Gtk.TreeModelFilter (model, null);
			filtered_model.set_visible_func((model, iter) => {
				bool visible = false;
				TemplateDefinition definition;
				model.@get (iter, 1, out definition);
				Gtk.TreeIter language_iter;
				
				visible = combobox_languages.get_active_iter (out language_iter);
				if (visible) {
					var language_model = combobox_languages.get_model ();
					string selected_language;
					language_model.get (language_iter, 0, out selected_language);
					visible = selected_language == definition.language;
				}			
				if (visible) {
					foreach (string tag in definition.tags) {
						var tag_item = tag_cloud.get_item_with_text (tag);
						if (tag_item != null) {
							if (tag_item.select_status == SelectStatus.EXCLUDED) {
								visible = false;
								break; // no need to check futher tags
							} else if (tag_item.select_status == SelectStatus.SELECTED) {
								visible = true; // continue with the check to see if it's excluded
							}
						}
					}
				}
				
				return visible;
			});
			
			project_type_iconview.set_model (filtered_model);
			project_type_iconview.select_path (new Gtk.TreePath.from_string (selected_id.to_string ()));
			
			license_combobox = builder.get_object ("combobox-project-license") as Gtk.ComboBox;
			assert (license_combobox != null);
			// add the required cell renderer
			renderer = new Gtk.CellRendererText ();
			license_combobox.pack_start (renderer, true);
			license_combobox.add_attribute (renderer, "text", 0);

			model = license_combobox.get_model () as Gtk.ListStore;
			assert (model != null);
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

	private void refilter_projects ()
	{
		var model = project_type_iconview.get_model () as Gtk.TreeModelFilter;
		if (model != null) {
			model.refilter ();
		}

		if (project_type_iconview.get_selected_items ().length () <= 0) {
			project_type_iconview.select_path (new Gtk.TreePath.from_string ("0"));
		}
		if (project_type_iconview.get_selected_items ().length () > 0) {
			button_create_project.set_sensitive (true);
		} else {
			button_create_project.set_sensitive (false);
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
			if (project_type_iconview.get_selected_items ().length () > 0) {
				Gtk.TreeIter iter;
				Gtk.TreePath path = project_type_iconview.get_selected_items ().nth_data (0);
				var model = project_type_iconview.get_model () as Gtk.TreeModelFilter;
				if (model.get_iter (out iter, path)) {

					TemplateDefinition template = null;
					model.@get (iter, 1, out template);
					options.template = template;
				}
			}
		}
		return response;
	}
}

