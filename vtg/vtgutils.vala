/*
 *  vtgutils.vala - Vala developer toys for GEdit
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
using Gtk;
using Afrodite;
using Vbf;

namespace Vtg
{
	public errordomain ProjectManagerError
	{
		NO_BACKEND
	}
	
	public enum VcsTypes
	{
		NONE,
		GIT,
		BZR,
		SVN
	}
	
	namespace Interaction
	{
		public static void error_message (string message, Error err)
		{
			var dialog = new MessageDialog (null,
                                  DialogFlags.DESTROY_WITH_PARENT,
                                  MessageType.ERROR,
                                  ButtonsType.CLOSE,
			          message);
			dialog.secondary_text = err.message;
			dialog.run ();
			dialog.destroy ();
		}
		
		public static void info_message (string message)
		{
			var dialog = new MessageDialog (null,
                                  DialogFlags.DESTROY_WITH_PARENT,
                                  MessageType.INFO,
                                  ButtonsType.CLOSE,
			          message);
			dialog.run ();
			dialog.destroy ();
		}
	}
	
	public class Caches
	{
		private const int CACHE_LIMIT = 20;
		
		private static Gtk.ListStore _build_cache = null;
		private static Gtk.ListStore _compile_cache = null;
		private static Gtk.ListStore _configure_cache = null;
		private static Gtk.ListStore _executer_cache = null;
		
		public static Gtk.ListStore get_build_cache ()
		{
			if (_build_cache == null) {
				_build_cache = new Gtk.ListStore (1, typeof (string));
			}
			
			return _build_cache;
		}

		public static Gtk.ListStore get_compile_cache ()
		{
			if (_compile_cache == null) {
				_compile_cache = new Gtk.ListStore (1, typeof (string));
			}
			
			return _compile_cache;
		}

		public static Gtk.ListStore get_configure_cache ()
		{
			if (_configure_cache == null) {
				_configure_cache = new Gtk.ListStore (1, typeof (string));
			}
			
			return _configure_cache;
		}

		public static Gtk.ListStore get_executer_cache ()
		{
			if (_executer_cache == null) {
				_executer_cache = new Gtk.ListStore (1, typeof (string));
			}
			
			return _executer_cache;
		}
		
		public static bool cache_contains (Gtk.ListStore cache, string data)
		{
			TreeIter iter;
			bool found = false;
			
			if (cache.get_iter_first (out iter)) {
				do {
					string tmp;
					cache.get (iter, 0, out tmp);
					if (tmp == data) {
						found = true;
						break;
					}
				} while (cache.iter_next (ref iter));
			}
			return found;
		}
		
		public static bool cache_remove (Gtk.ListStore cache, string data)
		{
			TreeIter iter;
			bool found = false;
			
			if (cache.get_iter_first (out iter)) {
				do {
					string tmp;
					cache.get (iter, 0, out tmp);
					if (tmp == data) {
						found = true;
						cache.remove (iter);
						break;
					}
				} while (cache.iter_next (ref iter));
			}
			return found;
		}
		
		public static void cache_add (Gtk.ListStore cache, string data)
		{
			TreeIter iter;
			if (cache_count (cache) > CACHE_LIMIT) {
				if (cache.get_iter_first (out iter)) {
					TreeIter target = iter;
					//find last iter
					while (cache.iter_next (ref iter)) {
						target = iter;
					}
					cache.remove (target);
				}
			}
			cache.insert (out iter, 0);
			cache.set (iter, 0, data);
		}
		
		public static int cache_count (Gtk.ListStore cache)
		{
			int count = 0;
			TreeIter iter;
			if (cache.get_iter_first (out iter)) {
				do {
					count++;
				} while (cache.iter_next (ref iter));

			}
			return count;
		}
	}
	
	namespace StringUtils
	{
		public static bool is_null_or_empty (string? data)
		{
			return data == null || data == "";
		}
		
		public static string replace (string data, string search, string replace) 
		{
			try {
				var regex = new GLib.Regex (GLib.Regex.escape_string (search));
				return regex.replace_literal (data, -1, 0, replace);
			} catch (GLib.RegexError e) {
				GLib.assert_not_reached ();
			}
		}
	}
	
	namespace PathUtils
	{
		public static string normalize_path (string name)
		{
			if (name == null || name.length < 2)
				return name;
				
			string[] name_parts = name.substring (1, name.length - 1).split ("/");
			string last_item = null;

			string target_name = "";

			foreach (string item in name_parts) {
				if (item != "..") {
					if (last_item != null) {
						target_name += "/" + last_item;
					}

					last_item = item;
				} else {
					last_item = null;
				}
			}

			if (last_item != null && last_item != "..") {
				target_name += "/" + last_item;
			}

			return target_name;
		}
		
		public static int compare_vala_filenames (string filea, string fileb)
		{
			string dataa = filea;
			string datab = fileb;
			
			if (dataa.has_suffix (".vala") || dataa.has_suffix(".vapi")) {
				dataa = dataa.substring (0, dataa.length - 5);
			} else if (dataa.has_suffix (".gs")) {
				dataa = dataa.substring(0, dataa.length-3);
			}
			if (datab.has_suffix (".vala") || datab.has_suffix(".vapi")) {
				datab = datab.substring (0, datab.length - 5);
			} else if (datab.has_suffix (".gs")) {
				datab = datab.substring(0, datab.length-3);
			}
			return strcmp (dataa, datab);
		}
	}
	
	public class Utils : GLib.Object
	{
		private static bool _initialized = false;
		//private static Gtk.SourceCompletionItem[] _proposals = null;
		private static Vala.List<Package> _available_packages = null;
		private static Gtk.Builder _builder = null;
		private static string[] _vala_keywords = new string[] {
				"var", "out", "ref", "const",
				"static", "inline", "readonly", "async", "abstract",
				"public", "protected", "private", "internal",
				"this", "base",
				"if", "while", "do", "else", "return",
				"try", "catch",
				"class", "struct", "interface", "enum", "signal", "delegate"
		};

		//public const int prealloc_count = 500;

		public static Gdk.Pixbuf icon_generic;
		public static Gdk.Pixbuf icon_field;
		public static Gdk.Pixbuf icon_method;
		public static Gdk.Pixbuf icon_class;
		public static Gdk.Pixbuf icon_struct;
		public static Gdk.Pixbuf icon_property;
		public static Gdk.Pixbuf icon_signal;
		public static Gdk.Pixbuf icon_iface;
		public static Gdk.Pixbuf icon_const;
		public static Gdk.Pixbuf icon_enum;
		public static Gdk.Pixbuf icon_namespace;

		public static Gdk.Pixbuf icon_project;
		public static Gdk.Pixbuf icon_folder_packages;
		public static Gdk.Pixbuf icon_package;

		public static Gdk.Pixbuf icon_project_library_16;
		public static Gdk.Pixbuf icon_project_library_22;
		
		public static Gdk.Pixbuf icon_project_unknown_16;
		public static Gdk.Pixbuf icon_project_unknown_22;

		public static Gdk.Pixbuf icon_project_data_16;
		public static Gdk.Pixbuf icon_project_data_22;

		public static Gdk.Pixbuf icon_project_executable_16;
		public static Gdk.Pixbuf icon_project_executable_22;
		
		[Diagnostics]
		[PrintfFormat]
		internal static inline void trace (string format, ...)
		{
#if DEBUG
			var va = va_list ();
			var va2 = va_list.copy (va);
			Afrodite.Utils.log_message ("ValaToys", format, va2);
#endif
		}
	
		public static bool is_vala_doc (Gedit.Document doc)
		{
			return doc.language != null && (doc.language.id == "vala" || doc.language.id == "genie");
		}

		public static bool is_inside_comment_or_literal (GtkSource.Buffer src, TextIter pos)
		{
			bool res = false;
			
			if (src.iter_has_context_class (pos, "comment")) {
				res = true;
			} else {
				// iter_has_context_class returns false even when
				// the cursor is in the last position of a comment|
				if (pos.is_end () || pos.get_char () == '\n') {
					if (pos.backward_char ()) {
						if (src.iter_has_context_class (pos, "comment")) {
							res = true;
						} else {
							// repos the iter
							pos.forward_char ();
						}
					}
				}
			}

			if (!res) {
				if (src.iter_has_context_class (pos, "string")) {
					if (!pos.is_start () && pos.get_char () == '"') {
						// iter_has_context_class returns true even when
						// |"the cursor is just before the string"
						if (pos.backward_char ()) {
							if (src.iter_has_context_class (pos, "string")) {
								res = true;
							} else {
								// repos the iter
								pos.forward_char ();
							}
						}
					}
				}
			}

			return res;
		}

		public static bool is_vala_keyword (string word)
		{
			bool res = false;
			foreach (string keyword in _vala_keywords) {
				if (keyword == word) {
					res = true;
					break;
				}
			}
			return res;
		}
		
		public static string get_document_uri (Gedit.Document doc)
		{
			string result = null;
			var file = doc.get_location ();
			if (file != null)
			   result = file.get_uri ();

			return result;
		}

		public static string get_document_name (Gedit.Document doc)
		{
			string name = get_document_uri (doc);
			if (name == null) {
				name = doc.get_short_name_for_display ();
			} else {
				try {
					name = Filename.from_uri (name);
				} catch (Error e) {
					GLib.warning ("error %s converting file %s to uri", e.message, name);
				}
			}

			if (is_vala_doc(doc) && (!name.has_suffix (".vala") && !name.has_suffix (".vapi") && !name.has_suffix (".gs"))) {
				if (get_source_type (doc) == SourceType.GENIE) {
					name += ".gs";
				} else {
					name += ".vala";
				}
			}
			return name;
		}

		public static SourceType get_source_type (Gedit.Document doc)
		{
			if (doc.language != null) {
				if (doc.language.id == "vala") {
					string name = doc.location.get_uri ();
					if (name != null && name.has_suffix (".vapi")) {
						return SourceType.VAPI;
					} else {
						return SourceType.VALA;
					}
				} else if (doc.language.id == "genie") {
					return SourceType.GENIE;
				}
			}
			
			return SourceType.UNKNOWN;
		}

		public static Gtk.Builder get_builder ()
		{
			if (_builder == null) {
				_builder = new Gtk.Builder ();
				try {
					_builder.add_from_file (get_ui_path ("vtg.ui"));
				} catch (Error err) {
					GLib.warning ("initialize_ui: %s", err.message);
				}
			}	
			return _builder;
		}
		
		/*public static unowned Gtk.SourceCompletionItem[] get_proposal_cache ()
		{
			if (!_initialized) {
				initialize ();
			}
			return _proposals;
		}*/

		public static string get_image_path (string id) {
			var result = Path.build_filename (Config.PACKAGE_DATADIR, "images", id);
			return result;
		}

		public static string get_ui_path (string id) {
			var result = Path.build_filename (Config.PACKAGE_DATADIR, "ui", id);
			return result;
		}

		private static void initialize ()
		{
			try {
				/*_proposals = new Gtk.SourceCompletionItem[prealloc_count];
				var _icon_generic = IconTheme.get_default().load_icon(Gtk.STOCK_FILE,16,IconLookupFlags.GENERIC_FALLBACK);
				for (int idx = 0; idx < prealloc_count; idx++) {
					var obj = new Gtk.SourceCompletionItem ("", "", _icon_generic, "");
					_proposals[idx] = obj;
				}*/
			
				icon_generic = IconTheme.get_default().load_icon(Gtk.Stock.FILE,16,IconLookupFlags.GENERIC_FALLBACK);
				icon_field = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-field-16.png"));
				icon_method = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-method-16.png"));
				icon_class = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-class-16.png"));
				icon_struct = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-structure-16.png"));
				icon_property = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-property-16.png"));
				icon_signal = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-event-16.png"));
				icon_iface = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-interface-16.png"));
				icon_enum = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-enumeration-16.png"));
				icon_const = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-literal-16.png"));
				icon_namespace = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-namespace-16.png"));	

				icon_project = new Gdk.Pixbuf.from_file (Utils.get_image_path ("project-16.png"));
				icon_folder_packages = new Gdk.Pixbuf.from_file (Utils.get_image_path ("project-reference-folder-16.png"));
				icon_package = new Gdk.Pixbuf.from_file (Utils.get_image_path ("package-16.png"));

				icon_project_library_16 = new Gdk.Pixbuf.from_file (Utils.get_image_path ("project-library-16.png"));
				icon_project_library_22 = new Gdk.Pixbuf.from_file (Utils.get_image_path ("project-library-22.png"));
				
				icon_project_unknown_16 = new Gdk.Pixbuf.from_file (Utils.get_image_path ("project-unknown-16.png"));
				icon_project_unknown_22 = new Gdk.Pixbuf.from_file (Utils.get_image_path ("project-unknown-22.png"));

				icon_project_data_16 = new Gdk.Pixbuf.from_file (Utils.get_image_path ("project-data-16.png"));
				icon_project_data_22 = new Gdk.Pixbuf.from_file (Utils.get_image_path ("project-data-22.png"));

				icon_project_executable_16 = IconTheme.get_default().load_icon (Gtk.Stock.EXECUTE,16,IconLookupFlags.GENERIC_FALLBACK);
				icon_project_executable_22 = IconTheme.get_default().load_icon (Gtk.Stock.EXECUTE,22,IconLookupFlags.GENERIC_FALLBACK);
				
				_initialized = true;
			} catch (Error err) {
				warning (err.message);
			}
		}

		public static Vala.List<Package> get_available_packages ()
		{
			if (_available_packages == null) {
				initialize_packages_cache ();
			}
			return _available_packages;
		}

		private static void initialize_packages_cache ()
		{
			List<string> vapidirs = new List<string> ();
		        vapidirs.append (Config.VALA_VAPIDIR);
			vapidirs.append ("/usr/local/share/vala/vapi");

			_available_packages = new Vala.ArrayList<Package> ();

			foreach (string vapidir in vapidirs) {
				Dir dir;
				try {					      
					dir = Dir.open (vapidir);
				} catch (FileError err) {
					//do nothing
					continue;
				}
				string? filename = dir.read_name ();
				while (filename != null) {
					if (filename.has_suffix (".vapi")) {
						filename = filename.down ();
						_available_packages.add (new Package (filename.substring (0, filename.length - 5)));
					}
					filename = dir.read_name ();
				}
			}
		}
		
		public static Gdk.Pixbuf get_icon_for_type_name (MemberType type)
		{
			if (!_initialized) {
				initialize ();
			}
			if (icon_namespace != null && type == MemberType.NAMESPACE)
				return icon_namespace;
			else if (icon_class != null 
				&& (type == MemberType.CLASS
					|| type == MemberType.CREATION_METHOD
					|| type == MemberType.DESTRUCTOR 
					|| type == MemberType.CONSTRUCTOR
					|| type == MemberType.ERROR_DOMAIN))
				return icon_class;
			else if (icon_struct != null && type == MemberType.STRUCT)
				return icon_struct;
			else if (icon_iface != null && type == MemberType.INTERFACE)
				return icon_iface;
			else if (icon_field != null && type == MemberType.FIELD)
				return icon_field;
			else if (icon_property != null && type == MemberType.PROPERTY)
				return icon_property;
			else if (icon_method != null && (type == MemberType.METHOD || type == MemberType.DELEGATE))
				return icon_method;
			else if (icon_enum != null && type == MemberType.ENUM)
				return icon_enum;
			else if (icon_const != null && (type == MemberType.CONSTANT || type == MemberType.ENUM_VALUE || type == MemberType.ERROR_CODE))
				return icon_const;
			else if (icon_signal != null && type == MemberType.SIGNAL)
				return icon_signal;

			return icon_generic;
		}

		public static string get_stock_id_for_target_type_to_delete (Vbf.TargetTypes type)
		{
			switch (type) {
				case TargetTypes.PROGRAM:
					return Gtk.Stock.EXECUTE;
				case TargetTypes.LIBRARY:
					return Gtk.Stock.EXECUTE;
				case TargetTypes.DATA:
					return Gtk.Stock.DIRECTORY;
				case TargetTypes.BUILT_SOURCES:
					return Gtk.Stock.EXECUTE;
				default:
					return Gtk.Stock.DIRECTORY;
			}
		}

		public static Gdk.Pixbuf get_small_icon_for_target_type (Vbf.TargetTypes type)
		{
			switch (type) {
				case TargetTypes.PROGRAM:
					return icon_project_executable_16;
				case TargetTypes.LIBRARY:
					return icon_project_library_16;
				case TargetTypes.DATA:
					return icon_project_data_16;
				case TargetTypes.BUILT_SOURCES:
					return icon_project_executable_16;
				default:
					return icon_project_unknown_16;
			}
		}

		public static Gdk.Pixbuf get_big_icon_for_target_type (Vbf.TargetTypes type)
		{
			switch (type) {
				case TargetTypes.PROGRAM:
					return icon_project_executable_22;
				case TargetTypes.LIBRARY:
					return icon_project_library_22;
				case TargetTypes.DATA:
					return icon_project_data_22;
				case TargetTypes.BUILT_SOURCES:
					return icon_project_executable_22;
				default:
					return icon_project_unknown_22;
			}
		}		
		
		public static int symbol_type_compare (Symbol? vala, Symbol? valb)
		{
			// why I get vala or valb with null???
			if (vala == null && valb == null)
				return 0;
			else if (vala == null && valb != null)
				return 1;
			else if (vala != null && valb == null)
				return -1;
		
			if (vala.member_type != valb.member_type) {
				if (vala.member_type == MemberType.CONSTANT) {
					return -1;
				} else if (valb.member_type == MemberType.CONSTANT) {
					return 1;
				} else if (vala.member_type == MemberType.ENUM) {
					return -1;
				} else if (valb.member_type == MemberType.ENUM) {
					return 1;
				} else if (vala.member_type == MemberType.FIELD) {
					return -1;
				} else if (valb.member_type == MemberType.FIELD) {
					return 1;
				} else if (vala.member_type == MemberType.PROPERTY) {
					return -1;
				} else if (valb.member_type == MemberType.PROPERTY) {
					return 1;
				} else if (vala.member_type == MemberType.SIGNAL) {
					return -1;
				} else if (valb.member_type == MemberType.SIGNAL) {
					return 1;
				} else if (vala.member_type == MemberType.CREATION_METHOD) {
					return -1;
				} else if (valb.member_type == MemberType.CREATION_METHOD) {
					return 1;
				} else if (vala.member_type == MemberType.CONSTRUCTOR) {
					return -1;
				} else if (valb.member_type == MemberType.CONSTRUCTOR) {
					return 1;
				} else if (vala.member_type == MemberType.METHOD) {
					return -1;
				} else if (valb.member_type == MemberType.METHOD) {
					return 1;
				} else if (vala.member_type == MemberType.ERROR_DOMAIN) {
					return -1;
				} else if (valb.member_type == MemberType.ERROR_DOMAIN) {
					return 1;
				} else if (vala.member_type == MemberType.NAMESPACE) {
					return -1;
				} else if (valb.member_type == MemberType.NAMESPACE) {
					return 1;
				} else if (vala.member_type == MemberType.STRUCT) {
					return -1;
				} else if (valb.member_type == MemberType.STRUCT) {
					return 1;
				} else if (vala.member_type == MemberType.CLASS) {
					return -1;
				} else if (valb.member_type == MemberType.CLASS) {
					return 1;
				} else if (vala.member_type == MemberType.INTERFACE) {
					return -1;
				} else if (valb.member_type == MemberType.INTERFACE) {
					return 1;
				}
			}
			return GLib.strcmp0 (vala.name, valb.name);
		}
	}
	
	namespace ParserUtils
	{
		/**
		 * Utility method to get the text from the start iter
		 * to the end of line.
		 *
		 * @param start start iter from which start to get the text (this iter will not be modified)
		 * @return the text from the start iter to the end of line or an empty string if the iter is already on the line end.
		 */
		public static string get_line_to_end (TextIter start)
		{
			string text = "";
			
			TextIter end = start;
			end.set_line_offset (0);
			if (end.forward_to_line_end ()) {
				text = start.get_text (end);
			}
			
			return text;
		}
		
		public static void parse_line (string line, out string token, out bool is_assignment, out bool is_creation, out bool is_declaration)
		{
			token = "";
			is_assignment = false;
			is_creation = false;
			is_declaration = false;

			int i = (int)line.length - 1;
			string tok;
			int count = 0;
			token = get_token (line, ref i);
			if (token != null) {
				count = 1;
				string last_token = token;
				while ((tok = get_token (line, ref i)) != null) {
					count++;
					if (tok == "=") {
						//token = "";
						is_assignment = true;
					} else if (tok == "new") {
						//token = "";
						is_creation = true;
					}
					last_token = tok;
				}
			
				if (!is_assignment && !is_creation && count == 2) {
					if (last_token == "var" 
					    || (!Utils.is_vala_keyword (last_token) 
					        && !last_token.has_prefix ("\"") 
					        && !last_token.has_prefix ("'"))) {
						is_declaration = true;
					}
				}
				if (token.has_suffix ("."))
					token = token.substring (0, token.length - 1);
			}
			Utils.trace ("parse line new: '%s'. is_assignment: %d is_creation: %d is_declaration: %d token: '%s'", line, (int)is_assignment, (int)is_creation, (int)is_declaration, token);
		}
		
		private static string? get_token (string line, ref int i)
		{
			string tok = "";
			int skip_lev = 0;
			bool in_string = false;
			bool should_skip_spaces = true; // skip spaces on enter
			
			while (!is_eof (line, i)) {
				if (should_skip_spaces) {
					i = skip_spaces (line, i);
					should_skip_spaces = false;
				}
				
				if (!is_eof (line, i)) {
					unichar ch = line[i];
					if (skip_lev == 0) {
						if (ch == '"' || ch == '\'') {
							tok = ch.to_string () + tok;
							if (!in_string) {
								in_string = true;
							} else {
								in_string = false;
							}
						} else if (ch == '_' || ch == '.' || (tok.length == 0 && ch.isalpha ()) || (tok.length > 0 && ch.isalnum ())) {
							// valid identifier
							tok = ch.to_string () + tok;
						} else if (ch == ' ' || ch == '=' || ch == '!' || ch == '<' || ch == '>') {
							if (in_string) {
								tok = ch.to_string () + tok;
							} else
								break;
						}
					}

					if (!in_string) {
						if (ch == '(' || ch == '[' || ch == '{') {
							if (skip_lev > 0) {
								skip_lev--;
								if (skip_lev == 0) {
									should_skip_spaces = true; // skip the spaces before (
								}
							} else {
								break;
							}
						} else if (ch == ')' || ch == ']' || ch == '}') {
							skip_lev++;
						}
					}
					i--;
				}
			}

			return tok == "" ? null : tok;
		}
		
		private static int skip_spaces (string line, int i)
		{
			unichar ch = line[i];
			while (!is_eof (line, i) && (ch == ' ' || ch == '\t' || ch.isspace ())) {
				i--;
				ch = line[i];
			}
			
			return i;
		}

		private static bool is_eof (string line, int i)
		{
			return i < 0;
		}
	}

	namespace LanguageSupport
	{
		public static GLib.Regex get_using_regex (Gedit.Document doc) throws GLib.RegexError
		{
			if (Utils.get_source_type (doc) == SourceType.GENIE) {
				//return new GLib.Regex ("""^\s*(uses)\s+(\w\S*).*$\n\s+(\w\S*)""", GLib.RegexCompileFlags.MULTILINE);
				return new GLib.Regex ("""^(uses|\t+|\s+)(\w\S*)\s*\n""", GLib.RegexCompileFlags.MULTILINE);
			} else {
				return new GLib.Regex ("""^\s*(using)\s+(\w\S*)\s*;.*$""", GLib.RegexCompileFlags.MULTILINE);
			}
		}
	}
}
