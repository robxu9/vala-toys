/*
 *  vtgprojectmanagermodulesdialog.vala - Vala developer toys for GEdit
 *  
 *  Copyright (C) 2008 - Andrea Del Signore <sejerpz@tin.it>
 *  
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *   
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *   
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330,
 *  Boston, MA 02111-1307, USA.
 */

using GLib;
using Gedit;
using Gdk;
using Gtk;

namespace Vtg.ProjectManager
{
	public class PackagesDialog
	{
		private ProjectModule _module;
		private Gee.List<ProjectModule> _modules;
		private Gtk.Dialog _dialog;
		private Gtk.TreeView _treeview;

		public PackagesDialog (ProjectModule module, Gee.List<ProjectModule> modules)
		{
			_modules = modules;
			_module = module;
			initialize_ui ();
		}

		private void initialize_ui ()
		{
			
			var builder = new Gtk.Builder ();
			try {
				builder.add_from_file (Utils.get_ui_path ("vtg.ui"));
			} catch (Error err) {
				GLib.warning ("initialize_ui: %s", err.message);
			}
			
			_dialog = (Gtk.Dialog) builder.get_object ("dialog-lm");
			assert (_dialog != null);
			var vbox = (Gtk.VBox) builder.get_object ("dialog-vbox-lm");
			assert (vbox != null);
			vbox.pack_start (_module.project.gbf_project.configure (), true, true, 8);
			
		}

		public void show ()
		{
			_dialog.run ();
			_dialog.destroy ();
			_dialog = null;
		}
/*
		private ListStore build_packages_model ()
		{
			ListStore store = new ListStore (3, typeof(bool), typeof(string), typeof(GLib.Object));
			foreach (ProjectPackage package in Utils.get_available_packages ()) {
				TreeIter iter;
				bool selected = modules_contain_package (package.id);
				store.append (out iter);
				store.set (iter, 0, selected, 1, package.name, package);
			}

			return store;
		}

		private bool modules_contain_package (string id)
		{
			foreach (ProjectModule module in _modules) {
				foreach (ProjectPackage package in module.packages) {
					if (id == package.id) {
						return true;
					}
				}
			}

			return false;
		}

		private void on_check_selected_only_toggled (Gtk.ToggleButton sender)
		{
			var model = _treeview.get_model ();
			
				GLib.debug ("pp3");
			if (sender.get_active ()) {
				GLib.debug ("pp");
				var filter = new TreeModelFilter (model, null);
				filter.set_visible_column (0);
				_treeview.set_model (filter);
			} else if (model is TreeModelFilter) {
				GLib.debug ("pp2");
				var child_model = ((TreeModelFilter) model).get_model ();
				_treeview.set_model (child_model);
			}
		}

		private void on_selected_packages_changed (Gtk.TreeModel model, Gtk.TreePath path, Gtk.TreeIter iter)
		{
			ProjectPackage package;
			bool selected;

			model.get (iter, 0, out selected, 2, out package);
			if (selected && !modules_contain_package (package.id)) {
				GLib.debug ("Adding package %s", package.id);
				//module.packages.add (package.id);
			}
		}
*/
	}
}
