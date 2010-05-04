/* valagenprojectdialog.vala
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

class Vala.GenProjectDialog
{
	private Gtk.Dialog config_dialog;
	private Gtk.FileChooserButton project_folder_button;
	private Gtk.ComboBox project_type_combobox;
	private Gtk.ComboBox license_combobox;
	private Gtk.Entry name_entry;
	private Gtk.Entry email_entry;

  private void initialize_ui (ProjectOptions options) {
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
		
		  hbox = builder.get_object ("hbox-project-type") as Gtk.HBox;
		  assert (hbox != null);
		  project_type_combobox = new Gtk.ComboBox.text ();
		  hbox.pack_start (project_type_combobox, true, true, 0);
		  project_type_combobox.append_text ("Console Application");
		  project_type_combobox.append_text ("GTK+ Application");
		  project_type_combobox.active = options.type;
		  project_type_combobox.show ();

		  license_combobox = builder.get_object ("combobox-project-license") as Gtk.ComboBox;
		  assert (license_combobox != null);
		  // add the required cell renderer
		  var renderer = new Gtk.CellRendererText ();
		  license_combobox.pack_start (renderer, true);
		  license_combobox.add_attribute (renderer, "text", 0);
		
		  var model = license_combobox.get_model () as Gtk.ListStore;
		  assert (model != null);
		  Gtk.TreeIter item;
		  model.append (out item);
		  model.set (item, 0, _("GNU General Public License, version 2 or later"), 1, Vala.ProjectLicense.GPL2);
		  model.append (out item);
		  model.set (item, 0, _("GNU General Public License, version 3 or later"), 1, Vala.ProjectLicense.GPL3);
		  model.append (out item);
		  model.set (item, 0, _("GNU Lesser General Public License, version 2.1 or later"), 1, Vala.ProjectLicense.LGPL2);
		  model.append (out item);
		  model.set (item, 0, _("GNU Lesser General Public License, version 3 or later"), 1, Vala.ProjectLicense.LGPL3);
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

  public Gtk.ResponseType ask_parameters (ref ProjectOptions options) {
	  Gtk.ResponseType response;

	  initialize_ui (options);
	  response = (Gtk.ResponseType) config_dialog.run ();
	  if (response == Gtk.ResponseType.OK) {
	    if (options.path == null)
		    options.path = project_folder_button.get_current_folder ();
		  options.name = Path.get_basename (options.path);
	    options.author = name_entry.text;
	    options.email = email_entry.text;
		  options.type = (ProjectType) project_type_combobox.active;
		  options.license = (ProjectLicense) license_combobox.active;
	  }
	  return response;
  }
}

