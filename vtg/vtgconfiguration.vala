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
		private const string VTG_SCHEMA_PREFERENCES = "org.gnome.gedit.plugins.vala-toys.preferences";
		private const string VTG_SCHEMA_STATE = "org.gnome.gedit.plugins.vala-toys.state";

		private GLib.Settings _settings_prefs;
		private GLib.Settings _settings_state;

		private bool _info_window_visible = false;
		private bool _outliner_show_private_symbols = false;
		private bool _outliner_show_public_symbols = false;
		private bool _outliner_show_protected_symbols = false;
		private bool _outliner_show_internal_symbols = false;
		private bool _project_only_show_sources = true;
		private bool _project_find_root_folder = true;

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
					_settings_state.set_boolean ("info-window-visible", _info_window_visible);
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
					_settings_state.set_boolean ("outliner-show-private-symbols", _outliner_show_private_symbols);
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
					_settings_state.set_boolean ("outliner-show-public-symbols", _outliner_show_public_symbols);
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
					_settings_state.set_boolean ("outliner-show-protected-symbols", _outliner_show_protected_symbols);
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
					_settings_state.set_boolean ("outliner-show-internal-symbols", _outliner_show_internal_symbols);
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
					_settings_state.set_boolean ("project-view-show-only-sources", _project_only_show_sources);
				}
			}
		}

		public bool project_find_root_folder
		{
			get {
				return _project_find_root_folder;
			}
			set {
				if (_project_find_root_folder != value) {
					_project_find_root_folder = value;
					_settings_prefs.set_boolean ("project-find-root-folder", _project_find_root_folder);
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
			_settings_prefs = new GLib.Settings (VTG_SCHEMA_PREFERENCES);
			_settings_state = new GLib.Settings (VTG_SCHEMA_STATE);

			_symbol_enabled = _settings_prefs.get_boolean ("symbol-completion-enabled");
			_bracket_enabled = _settings_prefs.get_boolean ("bracket-completion-enabled");
			_sourcecode_outliner_enabled = _settings_prefs.get_boolean ("sourcecode-outliner-enabled");
			_author = _settings_prefs.get_string ("author");
			_email_address = _settings_prefs.get_string ("email");
			_project_find_root_folder = _settings_prefs.get_boolean ("project-find-root-folder");

			_info_window_visible = _settings_state.get_boolean ("info-window-visible");
			_outliner_show_private_symbols = _settings_state.get_boolean ("outliner-show-private-symbols");
			_outliner_show_public_symbols = _settings_state.get_boolean ("outliner-show-public-symbols");
			_outliner_show_protected_symbols = _settings_state.get_boolean ("outliner-show-protected-symbols");
			_outliner_show_internal_symbols = _settings_state.get_boolean ("outliner-show-internal-symbols");
			_project_only_show_sources = _settings_state.get_boolean ("project-view-show-only-sources");

			_settings_prefs.changed.connect (this.on_conf_value_changed);
			_settings_state.changed.connect (this.on_conf_value_changed);
		}

		public Gtk.Widget? get_configuration_dialog ()
		{
			try {
				var builder = new Gtk.Builder ();
				builder.add_objects_from_file (Utils.get_ui_path ("vtg.ui"), new string[] { "vbox-settings-main" });

				var config_widget = (Gtk.Widget) builder.get_object ("vbox-settings-main");
				assert (config_widget != null);
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
				check = (Gtk.CheckButton) builder.get_object ("checkbutton-settings-project-find-root");
				assert (check != null);
				check.set_active (_project_find_root_folder);
				check.toggled.connect (this.on_checkbutton_toggled);
				var text = (Gtk.Entry) builder.get_object ("entry-settings-author");
				assert (text != null);
				text.set_text (_author);
				text.notify["text"].connect (this.on_text_changed);
				text = (Gtk.Entry) builder.get_object ("entry-settings-email");
				assert (text != null);
				text.set_text (_email_address);
				text.notify["text"].connect (this.on_text_changed);
				return config_widget;
			} catch (Error err) {
				GLib.warning ("(get_configuration_dialog): %s", err.message);
				return null;
			}
		}

		private void on_conf_value_changed (GLib.Settings sender, string key)
		{
			if (key == "bracket-completion-enabled") {
				var new_val = _settings_prefs.get_boolean ("bracket-completion-enabled");
				if (_bracket_enabled != new_val) {
					bracket_enabled = new_val;
				}
			} else if (key == "symbol-completion-enabled") {
				var new_val = _settings_prefs.get_boolean ("symbol-completion-enabled");
				if (_symbol_enabled != new_val) {
					symbol_enabled = new_val;
				}
			} else if (key == "sourcecode-outliner-enabled") {
				var new_val = _settings_prefs.get_boolean ("sourcecode-outliner-enabled");
				if (_sourcecode_outliner_enabled != new_val) {
					sourcecode_outliner_enabled = new_val;
				}
			} else if (key == "author") {
				var new_val = _settings_prefs.get_string ("author");
				if (_author != new_val) {
					author = new_val;
				}
			} else if (key == "email") {
				var new_val = _settings_prefs.get_string ("email");
				if (_email_address != new_val) {
					email_address = new_val;
				}
			} else if (key == "outliner-show-private-symbols") {
				var new_val = _settings_prefs.get_boolean ("outliner-show-private-symbols");
				if (_outliner_show_private_symbols != new_val) {
					outliner_show_private_symbols = new_val;
				}
			} else if (key == "outliner-show-public-symbols") {
				var new_val = _settings_prefs.get_boolean ("outliner-show-public-symbols");
				if (_outliner_show_public_symbols != new_val) {
					outliner_show_public_symbols = new_val;
				}
			} else if (key == "outliner-show-protected-symbols") {
				var new_val = _settings_prefs.get_boolean ("outliner-show-protected-symbols");
				if (_outliner_show_protected_symbols != new_val) {
					outliner_show_protected_symbols = new_val;
				}
			} else if (key == "outliner-show-internal-symbols") {
				var new_val = _settings_prefs.get_boolean ("outliner-show-internal-symbols");
				if (_outliner_show_internal_symbols != new_val) {
					outliner_show_internal_symbols = new_val;
				}
			} else if (key == "project-view-show-only-sources") {
				var new_val = _settings_prefs.get_boolean ("project-view-show-only-sources");
				if (_project_only_show_sources != new_val) {
					project_only_show_sources = new_val;
				}
			} else if (key == "project-find-root-folder") {
				var new_val = _settings_prefs.get_boolean ("project-find-root-folder");
				if (_project_find_root_folder != new_val) {
					project_find_root_folder = new_val;
				}
			}
		}

		private void on_checkbutton_toggled (Gtk.ToggleButton sender)
		{
			bool new_val = sender.get_active ();
			string name = sender.get_name ();

			if (name == "checkbutton-settings-bracket-completion") {
				_settings_prefs.set_boolean ("bracket-completion-enabled", new_val);
			} else if (name == "checkbutton-settings-symbol-completion") {
				_settings_prefs.set_boolean ("symbol-completion-enabled", new_val);
			} else if (name == "checkbutton-settings-sourcecode-outliner") {
				_settings_prefs.set_boolean ("sourcecode-outliner-enabled", new_val);
			} else if (name == "checkbutton-settings-project-find-root") {
				_settings_prefs.set_boolean ("project-find-root-folder", new_val);
			}
		}

		private void on_text_changed (GLib.Object sender, ParamSpec pspec)
		{
			var entry = (Gtk.Entry) sender;
			string new_val = entry.get_text ();
			string name = entry.get_name ();

			if (name == "entry-settings-author") {
				_settings_prefs.set_string ("author", new_val);
			} else if (name == "entry-settings-email") {
				_settings_prefs.set_string ("email", new_val);
			}
		}
	}
}
