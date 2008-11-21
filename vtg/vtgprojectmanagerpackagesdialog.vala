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
	}
}
