/*
 *  vtgconfigurationdialog.vala - Vala developer toys for GEdit
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

namespace Vtg
{
	public class Configuration : GLib.Object
	{		
		private const string VTG_BASE_KEY = "/apps/gedit-2/plugins/vtg";
		private const string VTG_ENABLE_SYMBOL_COMPLETION_KEY = VTG_BASE_KEY + "/bracket_completion_enabled";
		private const string VTG_ENABLE_BRACKET_COMPLETION_KEY = VTG_BASE_KEY + "/symbol_completion_enabled";

		private GConf.Client _gconf;
		private Gtk.Dialog _dialog;

		public bool bracket_enabled { get; set; }
		public bool symbol_enabled { get; set; }
		
		public bool save_before_build 
		{ 
			get {
				return true; //TODO: implement me!
			}
		}
		
		construct
		{
			try {
				GLib.debug ("starting");
				//TODO: construct the gconf client from Engine.get_defualt ()
				//when supported. See this bug for a similar issue
				//http://bugzilla.gnome.org/show_bug.cgi?id=549061
				_gconf = GConf.Client.get_default ();
				if (!_gconf.dir_exists ("/schemas" + VTG_BASE_KEY)) {
					GLib.debug ("creating configuration schemas");
					var schema = new GConf.Schema ();
					schema.set_short_desc (_("Enable the symbol completion module"));
					schema.set_type (GConf.ValueType.BOOL);
					var def_value = new GConf.Value (GConf.ValueType.BOOL);
					def_value.set_bool (true);
					schema.set_default_value (def_value);
					_gconf.set_schema("/schemas" + VTG_ENABLE_SYMBOL_COMPLETION_KEY, schema);
					schema.set_short_desc (_("Enable the bracket completion module"));
					schema.set_type (GConf.ValueType.BOOL);
					schema.set_default_value (def_value);
					_gconf.set_schema("/schemas" + VTG_ENABLE_BRACKET_COMPLETION_KEY, schema);
				}
				if (!_gconf.dir_exists (VTG_BASE_KEY)) {
					GLib.debug ("creating configuration keys");
					_gconf.set_bool (VTG_ENABLE_SYMBOL_COMPLETION_KEY, true);
					_gconf.set_bool (VTG_ENABLE_BRACKET_COMPLETION_KEY, true);
				}
				_gconf.engine.associate_schema (VTG_ENABLE_SYMBOL_COMPLETION_KEY, "/schemas" + VTG_ENABLE_SYMBOL_COMPLETION_KEY);
				_gconf.engine.associate_schema (VTG_ENABLE_BRACKET_COMPLETION_KEY, "/schemas" + VTG_ENABLE_BRACKET_COMPLETION_KEY);
				_symbol_enabled = _gconf.get_bool (VTG_ENABLE_SYMBOL_COMPLETION_KEY);
				_bracket_enabled = _gconf.get_bool (VTG_ENABLE_BRACKET_COMPLETION_KEY);;
				_gconf.add_dir (VTG_BASE_KEY, GConf.ClientPreloadType.ONELEVEL);
				_gconf.value_changed += this.on_conf_value_changed;
			} catch (Error err) {
				GLib.warning ("(configuration): %s", err.message);
			}
		}


		~Configuration ()
		{
			try {
				_gconf.suggest_sync ();
			} catch (Error err) {
				GLib.warning ("error %s", err.message);
			}
		}

		public weak Gtk.Widget? get_configuration_dialog ()
		{
			try {
				var builder = new Gtk.Builder ();
				builder.add_from_file (Utils.get_ui_path ("vtg.ui"));
				_dialog = (Gtk.Dialog) builder.get_object ("dialog-settings");
				assert (_dialog != null);
				var button = (Gtk.Button) builder.get_object ("button-settings-close");
				button.clicked += this.on_button_close_clicked;
				var check = (Gtk.CheckButton) builder.get_object ("checkbutton-settings-bracket-completion");
				assert (check != null);
				check.set_active (_bracket_enabled);
				check.toggled += this.on_checkbutton_toggled;
				check = (Gtk.CheckButton) builder.get_object ("checkbutton-settings-symbol-completion");
				assert (check != null);
				check.set_active (_symbol_enabled);
				check.toggled += this.on_checkbutton_toggled;

				return _dialog;
			} catch (Error err) {
				GLib.warning ("(get_configuration_dialog): %s", err.message);
				return null;
			}
		}

		private void on_button_close_clicked (Gtk.Button sender)
		{
			return_if_fail (_dialog != null);
			_dialog.destroy ();
		}

		private void on_conf_value_changed (GConf.Client sender, string key, void* value)
		{
			try {
				if (key == VTG_ENABLE_BRACKET_COMPLETION_KEY) {
					var new_val = _gconf.get_bool (VTG_ENABLE_BRACKET_COMPLETION_KEY);
					if (_bracket_enabled != new_val) {
						bracket_enabled = new_val;
					}
				} else if (key == VTG_ENABLE_SYMBOL_COMPLETION_KEY) {
					var new_val = _gconf.get_bool (VTG_ENABLE_SYMBOL_COMPLETION_KEY);
					if (_symbol_enabled != new_val) {
						symbol_enabled = new_val;
					}
				}
			} catch (Error err) {
				GLib.warning ("(on_conf_value_changed): %s", err.message);
			}
		}

		private void on_checkbutton_toggled (Gtk.ToggleButton sender)
		{
			try {
				bool new_val = sender.get_active ();
				string name = sender.get_name ();
				
				if (name == "checkbutton-settings-bracket-completion") {
					_gconf.set_bool (VTG_ENABLE_BRACKET_COMPLETION_KEY, new_val);
				} else if (name == "checkbutton-settings-symbol-completion") {
					_gconf.set_bool (VTG_ENABLE_SYMBOL_COMPLETION_KEY, new_val);
				}
			} catch (Error err) {
				GLib.warning ("(on_checkbutton_toggled): %s", err.message);
			}
		}
	}
}
