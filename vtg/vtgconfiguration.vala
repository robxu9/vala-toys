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
		private const string VTG_ENABLE_SOURCECODE_OUTLINER_KEY = VTG_BASE_KEY + "/sourcecode_outliner_enabled";
		private const string VTG_AUTHOR_KEY = VTG_BASE_KEY + "/author";
		private const string VTG_EMAIL_ADDRESS_KEY = VTG_BASE_KEY + "/email_address";
		private const string VTG_INFO_WINDOW_VISIBLE = VTG_BASE_KEY + "/info_window_visible";
		private const string VTG_OUTLINER_SHOW_PRIVATE_SYMBOLS = VTG_BASE_KEY + "/outliner_show_private_symbols";
		private const string VTG_OUTLINER_SHOW_PUBLIC_SYMBOLS = VTG_BASE_KEY + "/outliner_show_public_symbols";
		private const string VTG_OUTLINER_SHOW_PROTECTED_SYMBOLS = VTG_BASE_KEY + "/outliner_show_protected_symbols";
		private const string VTG_OUTLINER_SHOW_INTERNAL_SYMBOLS = VTG_BASE_KEY + "/outliner_show_internal_symbols";
		private const string VTG_PROJECT_VIEW_ONLY_SHOW_SOURCES = VTG_BASE_KEY + "/project_view_only_show_sources";
		
		private GConf.Client _gconf;
		private Gtk.Dialog _dialog;
		
		private bool _info_window_visible = false;
		private bool _outliner_show_private_symbols = false;
		private bool _outliner_show_public_symbols = false;
		private bool _outliner_show_protected_symbols = false;
		private bool _outliner_show_internal_symbols = false;
		private bool _project_only_show_sources = true;
		
		public bool bracket_enabled { get; set; }

		public bool symbol_enabled { get; set; }

		public bool sourcecode_outliner_enabled { get; set; }

		public string author { get; set; }

		public string email_address { get; set; }

		public bool info_window_visible
		{ 
			get {
				return _info_window_visible;
			}
			set {
				if (_info_window_visible != value) {
					_info_window_visible = value;
					try {
						_gconf.set_bool (VTG_INFO_WINDOW_VISIBLE, _info_window_visible);	
					} catch (Error e) {
						GLib.warning ("Error settings info_window_visible: %s", e.message);
					}
				}
			}
		}

		public bool outliner_show_private_symbols
		{ 
			get {
				return _outliner_show_private_symbols;
			}
			set {
				if (_outliner_show_private_symbols != value) {
					_outliner_show_private_symbols = value;
					try {
						_gconf.set_bool (VTG_OUTLINER_SHOW_PRIVATE_SYMBOLS, _outliner_show_private_symbols);	
					} catch (Error e) {
						GLib.warning ("Error settings outliner_show_private_symbols: %s", e.message);
					}
				}
			}
		}

		public bool outliner_show_public_symbols
		{ 
			get {
				return _outliner_show_public_symbols;
			}
			set {
				if (_outliner_show_public_symbols != value) {
					_outliner_show_public_symbols = value;
					try {
						_gconf.set_bool (VTG_OUTLINER_SHOW_PUBLIC_SYMBOLS, _outliner_show_public_symbols);
					} catch (Error e) {
						GLib.warning ("Error settings outliner_show_public_symbols: %s", e.message);
					}
				}
			}
		}

		public bool outliner_show_protected_symbols
		{ 
			get {
				return _outliner_show_protected_symbols;
			}
			set {
				if (_outliner_show_protected_symbols != value) {
					_outliner_show_protected_symbols = value;
					try {
						_gconf.set_bool (VTG_OUTLINER_SHOW_PROTECTED_SYMBOLS, _outliner_show_protected_symbols);
					} catch (Error e) {
						GLib.warning ("Error settings outliner_show_protected_symbols: %s", e.message);
					}
				}
			}
		}

		public bool outliner_show_internal_symbols
		{ 
			get {
				return _outliner_show_internal_symbols;
			}
			set {
				if (_outliner_show_internal_symbols != value) {
					_outliner_show_internal_symbols = value;
					try {
						_gconf.set_bool (VTG_OUTLINER_SHOW_INTERNAL_SYMBOLS, _outliner_show_internal_symbols);
					} catch (Error e) {
						GLib.warning ("Error settings outliner_show_internal_symbols: %s", e.message);
					}
				}
			}
		}

		public bool project_only_show_sources
		{ 
			get {
				return _project_only_show_sources;
			}
			set {
				if (_project_only_show_sources != value) {
					_project_only_show_sources = value;
					try {
						_gconf.set_bool (VTG_PROJECT_VIEW_ONLY_SHOW_SOURCES, _project_only_show_sources);	
					} catch (Error e) {
						GLib.warning ("Error settings project_only_show_sources: %s", e.message);
					}
				}
			}
		}
		
		public bool save_before_build 
		{ 
			get {
				return true; //TODO: implement me!
			}
		}
		
		
		public Configuration ()
		{
			try {
				//TODO: construct the gconf client from Engine.get_default ()
				//when supported. See this bug for a similar issue
				//http://bugzilla.gnome.org/show_bug.cgi?id=549061
				_gconf = GConf.Client.get_default ();
				bool exists_base = _gconf.dir_exists ("/schemas" + VTG_BASE_KEY);
				if (!exists_base || _gconf.get_schema ("/schemas" + VTG_ENABLE_SYMBOL_COMPLETION_KEY) == null) {
					var schema = new GConf.Schema ();
					schema.set_short_desc (_("Enable the symbol completion module"));
					schema.set_type (GConf.ValueType.BOOL);
					var def_value = new GConf.Value (GConf.ValueType.BOOL);
					def_value.set_bool (true);
					schema.set_default_value (def_value);
					_gconf.set_schema("/schemas" + VTG_ENABLE_SYMBOL_COMPLETION_KEY, schema);
					_gconf.set_bool (VTG_ENABLE_SYMBOL_COMPLETION_KEY, true);					
				}
				if (!exists_base || _gconf.get_schema ("/schemas" + VTG_ENABLE_BRACKET_COMPLETION_KEY) == null) {
					var schema = new GConf.Schema ();
					schema.set_short_desc (_("Enable the bracket completion module"));
					schema.set_type (GConf.ValueType.BOOL);
					var def_value = new GConf.Value (GConf.ValueType.BOOL);
					def_value.set_bool (true);
					schema.set_default_value (def_value);
					_gconf.set_schema("/schemas" + VTG_ENABLE_BRACKET_COMPLETION_KEY, schema);
					_gconf.set_bool (VTG_ENABLE_BRACKET_COMPLETION_KEY, true);					
				}
				if (!exists_base || _gconf.get_schema ("/schemas" + VTG_ENABLE_BRACKET_COMPLETION_KEY) == null) {
					var schema = new GConf.Schema ();
					schema.set_short_desc (_("Enable the source code outliner module"));
					schema.set_type (GConf.ValueType.BOOL);
					var def_value = new GConf.Value (GConf.ValueType.BOOL);
					def_value.set_bool (true);
					schema.set_default_value (def_value);
					_gconf.set_schema("/schemas" + VTG_ENABLE_SOURCECODE_OUTLINER_KEY, schema);
					_gconf.set_bool (VTG_ENABLE_SOURCECODE_OUTLINER_KEY, true);					
				}
				if (!exists_base || _gconf.get_schema ("/schemas" + VTG_AUTHOR_KEY) == null) {
					var schema = new GConf.Schema ();
					schema.set_short_desc (_("Override the author name used in the ChangeLog entries"));
					schema.set_type (GConf.ValueType.STRING);
					var def_value = new GConf.Value (GConf.ValueType.STRING);
					def_value.set_string ("");
					schema.set_default_value (def_value);
					_gconf.set_schema("/schemas" + VTG_AUTHOR_KEY, schema);
					_gconf.set_string (VTG_AUTHOR_KEY, "");
				}
				if (!exists_base || _gconf.get_schema ("/schemas" + VTG_EMAIL_ADDRESS_KEY) == null) {
					var schema = new GConf.Schema ();
					schema.set_short_desc (_("Override the author name used in the ChangeLog entries"));
					schema.set_type (GConf.ValueType.STRING);
					var def_value = new GConf.Value (GConf.ValueType.STRING);
					def_value.set_string ("");
					schema.set_default_value (def_value);
					_gconf.set_schema("/schemas" + VTG_EMAIL_ADDRESS_KEY, schema);
					_gconf.set_string (VTG_EMAIL_ADDRESS_KEY, "");
				}
				if (!exists_base || _gconf.get_schema ("/schemas" + VTG_INFO_WINDOW_VISIBLE) == null) {
					var schema = new GConf.Schema ();
					schema.set_short_desc (_("Store the completion info window visible status"));
					schema.set_type (GConf.ValueType.BOOL);
					var def_value = new GConf.Value (GConf.ValueType.BOOL);
					def_value.set_bool (true);
					schema.set_default_value (def_value);
					_gconf.set_schema("/schemas" + VTG_INFO_WINDOW_VISIBLE, schema);
					_gconf.set_bool (VTG_INFO_WINDOW_VISIBLE, false);					
				}				
				if (!exists_base || _gconf.get_schema ("/schemas" + VTG_OUTLINER_SHOW_PRIVATE_SYMBOLS) == null) {
					var schema = new GConf.Schema ();
					schema.set_short_desc (_("Store the source outliner show private symbol check button status"));
					schema.set_type (GConf.ValueType.BOOL);
					var def_value = new GConf.Value (GConf.ValueType.BOOL);
					def_value.set_bool (true);
					schema.set_default_value (def_value);
					_gconf.set_schema("/schemas" + VTG_OUTLINER_SHOW_PRIVATE_SYMBOLS, schema);
					_gconf.set_bool (VTG_OUTLINER_SHOW_PRIVATE_SYMBOLS, false);
				}
				if (!exists_base || _gconf.get_schema ("/schemas" + VTG_OUTLINER_SHOW_PUBLIC_SYMBOLS) == null) {
					var schema = new GConf.Schema ();
					schema.set_short_desc (_("Store the source outliner show public symbol check button status"));
					schema.set_type (GConf.ValueType.BOOL);
					var def_value = new GConf.Value (GConf.ValueType.BOOL);
					def_value.set_bool (true);
					schema.set_default_value (def_value);
					_gconf.set_schema("/schemas" + VTG_OUTLINER_SHOW_PUBLIC_SYMBOLS, schema);
					_gconf.set_bool (VTG_OUTLINER_SHOW_PUBLIC_SYMBOLS, false);
				}
				if (!exists_base || _gconf.get_schema ("/schemas" + VTG_OUTLINER_SHOW_PRIVATE_SYMBOLS) == null) {
					var schema = new GConf.Schema ();
					schema.set_short_desc (_("Store the source outliner show protected symbol check button status"));
					schema.set_type (GConf.ValueType.BOOL);
					var def_value = new GConf.Value (GConf.ValueType.BOOL);
					def_value.set_bool (true);
					schema.set_default_value (def_value);
					_gconf.set_schema("/schemas" + VTG_OUTLINER_SHOW_PROTECTED_SYMBOLS, schema);
					_gconf.set_bool (VTG_OUTLINER_SHOW_PROTECTED_SYMBOLS, false);
				}
				if (!exists_base || _gconf.get_schema ("/schemas" + VTG_OUTLINER_SHOW_INTERNAL_SYMBOLS) == null) {
					var schema = new GConf.Schema ();
					schema.set_short_desc (_("Store the source outliner show internal symbol check button status"));
					schema.set_type (GConf.ValueType.BOOL);
					var def_value = new GConf.Value (GConf.ValueType.BOOL);
					def_value.set_bool (true);
					schema.set_default_value (def_value);
					_gconf.set_schema("/schemas" + VTG_OUTLINER_SHOW_INTERNAL_SYMBOLS, schema);
					_gconf.set_bool (VTG_OUTLINER_SHOW_INTERNAL_SYMBOLS, false);
				}

				if (!exists_base || _gconf.get_schema ("/schemas" + VTG_PROJECT_VIEW_ONLY_SHOW_SOURCES) == null) {
					var schema = new GConf.Schema ();
					schema.set_short_desc (_("Store the project view show only sources check button status"));
					schema.set_type (GConf.ValueType.BOOL);
					var def_value = new GConf.Value (GConf.ValueType.BOOL);
					def_value.set_bool (true);
					schema.set_default_value (def_value);
					_gconf.set_schema("/schemas" + VTG_PROJECT_VIEW_ONLY_SHOW_SOURCES, schema);
					_gconf.set_bool (VTG_PROJECT_VIEW_ONLY_SHOW_SOURCES, true);
				}				
				_gconf.engine.associate_schema (VTG_ENABLE_SYMBOL_COMPLETION_KEY, "/schemas" + VTG_ENABLE_SYMBOL_COMPLETION_KEY);
				_gconf.engine.associate_schema (VTG_ENABLE_BRACKET_COMPLETION_KEY, "/schemas" + VTG_ENABLE_BRACKET_COMPLETION_KEY);
				_gconf.engine.associate_schema (VTG_ENABLE_SOURCECODE_OUTLINER_KEY, "/schemas" + VTG_ENABLE_SOURCECODE_OUTLINER_KEY);
				_gconf.engine.associate_schema (VTG_AUTHOR_KEY, "/schemas" + VTG_AUTHOR_KEY);
				_gconf.engine.associate_schema (VTG_EMAIL_ADDRESS_KEY, "/schemas" + VTG_EMAIL_ADDRESS_KEY);
				_gconf.engine.associate_schema (VTG_INFO_WINDOW_VISIBLE, "/schemas" + VTG_INFO_WINDOW_VISIBLE);
				_gconf.engine.associate_schema (VTG_OUTLINER_SHOW_PRIVATE_SYMBOLS, "/schemas" + VTG_OUTLINER_SHOW_PRIVATE_SYMBOLS);
				_gconf.engine.associate_schema (VTG_OUTLINER_SHOW_PUBLIC_SYMBOLS, "/schemas" + VTG_OUTLINER_SHOW_PUBLIC_SYMBOLS);
				_gconf.engine.associate_schema (VTG_OUTLINER_SHOW_PROTECTED_SYMBOLS, "/schemas" + VTG_OUTLINER_SHOW_PROTECTED_SYMBOLS);
				_gconf.engine.associate_schema (VTG_OUTLINER_SHOW_INTERNAL_SYMBOLS, "/schemas" + VTG_OUTLINER_SHOW_INTERNAL_SYMBOLS);
				_gconf.engine.associate_schema (VTG_PROJECT_VIEW_ONLY_SHOW_SOURCES, "/schemas" + VTG_PROJECT_VIEW_ONLY_SHOW_SOURCES);
				_symbol_enabled = _gconf.get_bool (VTG_ENABLE_SYMBOL_COMPLETION_KEY);
				_bracket_enabled = _gconf.get_bool (VTG_ENABLE_BRACKET_COMPLETION_KEY);
				_sourcecode_outliner_enabled = _gconf.get_bool (VTG_ENABLE_SOURCECODE_OUTLINER_KEY);
				_author = _gconf.get_string (VTG_AUTHOR_KEY);
				_email_address = _gconf.get_string (VTG_EMAIL_ADDRESS_KEY);
				_info_window_visible = _gconf.get_bool (VTG_INFO_WINDOW_VISIBLE);
				_outliner_show_private_symbols = _gconf.get_bool (VTG_OUTLINER_SHOW_PRIVATE_SYMBOLS);
				_outliner_show_public_symbols = _gconf.get_bool (VTG_OUTLINER_SHOW_PUBLIC_SYMBOLS);
				_outliner_show_protected_symbols = _gconf.get_bool (VTG_OUTLINER_SHOW_PROTECTED_SYMBOLS);
				_outliner_show_internal_symbols = _gconf.get_bool (VTG_OUTLINER_SHOW_INTERNAL_SYMBOLS);
				_project_only_show_sources = _gconf.get_bool (VTG_PROJECT_VIEW_ONLY_SHOW_SOURCES);
				_gconf.add_dir (VTG_BASE_KEY, GConf.ClientPreloadType.ONELEVEL);
				_gconf.value_changed.connect (this.on_conf_value_changed);
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

		public unowned Gtk.Widget? get_configuration_dialog ()
		{
			try {
				var builder = new Gtk.Builder ();
				builder.add_from_file (Utils.get_ui_path ("vtg.ui"));
				_dialog = (Gtk.Dialog) builder.get_object ("dialog-settings");
				assert (_dialog != null);
				var button = (Gtk.Button) builder.get_object ("button-settings-close");
				button.clicked.connect (this.on_button_close_clicked);
				var check = (Gtk.CheckButton) builder.get_object ("checkbutton-settings-bracket-completion");
				assert (check != null);
				check.set_active (_bracket_enabled);
				check.toggled.connect (this.on_checkbutton_toggled);
				check = (Gtk.CheckButton) builder.get_object ("checkbutton-settings-symbol-completion");
				assert (check != null);
				check.set_active (_symbol_enabled);
				check.toggled.connect (this.on_checkbutton_toggled);
				check = (Gtk.CheckButton) builder.get_object ("checkbutton-settings-sourcecode-outliner");
				assert (check != null);
				check.set_active (_sourcecode_outliner_enabled);
				check.toggled.connect (this.on_checkbutton_toggled);
				var text = (Gtk.Entry) builder.get_object ("entry-settings-author");
				assert (text != null);
				text.set_text (_author);
				text.notify["text"] += this.on_text_changed;
				text = (Gtk.Entry) builder.get_object ("entry-settings-email");
				assert (text != null);
				text.set_text (_email_address);
				text.notify["text"] += this.on_text_changed;
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
				} else if (key == VTG_ENABLE_SOURCECODE_OUTLINER_KEY) {
					var new_val = _gconf.get_bool (VTG_ENABLE_SOURCECODE_OUTLINER_KEY);
					if (_sourcecode_outliner_enabled != new_val) {
						sourcecode_outliner_enabled = new_val;
					}
				} else if (key == VTG_AUTHOR_KEY) {
					var new_val = _gconf.get_string (VTG_AUTHOR_KEY);
					if (_author != new_val) {
						author = new_val;
					}
				} else if (key == VTG_EMAIL_ADDRESS_KEY) {
					var new_val = _gconf.get_string (VTG_EMAIL_ADDRESS_KEY);
					if (_email_address != new_val) {
						email_address = new_val;
					}
				} else if (key == VTG_OUTLINER_SHOW_PRIVATE_SYMBOLS) {
					var new_val = _gconf.get_bool (VTG_OUTLINER_SHOW_PRIVATE_SYMBOLS);
					if (_outliner_show_private_symbols != new_val) {
						outliner_show_private_symbols = new_val;
					}
				} else if (key == VTG_OUTLINER_SHOW_PUBLIC_SYMBOLS) {
					var new_val = _gconf.get_bool (VTG_OUTLINER_SHOW_PUBLIC_SYMBOLS);
					if (_outliner_show_public_symbols != new_val) {
						outliner_show_public_symbols = new_val;
					}
				} else if (key == VTG_OUTLINER_SHOW_PROTECTED_SYMBOLS) {
					var new_val = _gconf.get_bool (VTG_OUTLINER_SHOW_PROTECTED_SYMBOLS);
					if (_outliner_show_protected_symbols != new_val) {
						outliner_show_protected_symbols = new_val;
					}
				} else if (key == VTG_OUTLINER_SHOW_INTERNAL_SYMBOLS) {
					var new_val = _gconf.get_bool (VTG_OUTLINER_SHOW_INTERNAL_SYMBOLS);
					if (_outliner_show_internal_symbols != new_val) {
						outliner_show_internal_symbols = new_val;
					}
				} else if (key == VTG_PROJECT_VIEW_ONLY_SHOW_SOURCES) {
					var new_val = _gconf.get_bool (VTG_PROJECT_VIEW_ONLY_SHOW_SOURCES);
					if (_project_only_show_sources != new_val) {
						project_only_show_sources = new_val;
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
				} else if (name == "checkbutton-settings-sourcecode-outliner") {
					_gconf.set_bool (VTG_ENABLE_SOURCECODE_OUTLINER_KEY, new_val);
				}
			} catch (Error err) {
				GLib.warning ("(on_checkbutton_toggled): %s", err.message);
			}
		}
		
		private void on_text_changed (GLib.Object sender, ParamSpec pspec)
		{
			try {
				var entry = (Gtk.Entry) sender;
				string new_val = entry.get_text ();
				string name = entry.get_name ();
				
				if (name == "entry-settings-author") {
					_gconf.set_string (VTG_AUTHOR_KEY, new_val);
				} else if (name == "entry-settings-email") {
					_gconf.set_string (VTG_EMAIL_ADDRESS_KEY, new_val);
				}
			} catch (Error err) {
				GLib.warning ("(on_text_changed): %s", err.message);
			}			
		}
	}
}
