/*
 *  vscparsermanager.vala - Vala symbol completion library
 *  
 *  Copyright (C) 2008 - Andrea Del Signore <sejerpz@tin.it>
 *  
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 */

using GLib;
using Vala;

namespace Vsc
{
	public class ParserManager : GLib.Object
	{
		private string glib_file;
		private string gobject_file;

		private List<string> _vapidirs = new List<string> ();
		private Gee.List<string> _packages = new Gee.ArrayList<string> ();
		private Gee.List<string> _sources = new Gee.ArrayList<string> ();
		private Gee.List<SourceBuffer> _source_buffers = new Gee.ArrayList<SourceBuffer> ();

		private CodeContext _pri_context;
		private CodeContext _sec_context;

		private int need_parse_sec_context = 0;
		private int need_parse_pri_context = 0;

		private weak Thread parser_pri_thread = null;
		private weak Thread parser_sec_thread = null;

		private Mutex mutex_pri_context = null;
		private Mutex mutex_sec_context = null;
	
		public signal void cache_building ();
		public signal void cache_builded ();

		construct
		{
			mutex_pri_context = new Mutex ();
			mutex_sec_context = new Mutex ();
			
			add_path_to_vapi_search_dir ("/usr/share/vala/vapi");
			add_path_to_vapi_search_dir ("/usr/local/share/vala/vapi");
			try {
				glib_file = find_vala_package_filename ("glib-2.0")[0];
			} catch (Error err) {
				error ("Can't find glib vapi file: %s", err.message);
			}

			try {
				gobject_file = find_vala_package_filename ("gobject-2.0")[0];
			} catch (Error err) {
				error ("Can't find gobject vapi file: %s", err.message);
			}
		}


		internal weak CodeContext pri_context
		{
			get {
				return _pri_context;
			}
		}
		
		internal weak CodeContext sec_context
		{
			get {
				return _sec_context;
			}
		}
		
		internal void lock_all_contexts ()
		{
			debug ("lock all context");
			mutex_pri_context.@lock ();
			mutex_sec_context.@lock ();
		}

	        internal void unlock_all_contexts ()
		{
			debug ("unlock all context");
			mutex_sec_context.unlock ();
			mutex_pri_context.unlock ();
		}

		internal void lock_pri_context ()
		{
			debug ("lock pri context");
			mutex_pri_context.@lock ();
		}

		internal void unlock_pri_context ()
		{
			debug ("unlock pri context");
			mutex_pri_context.unlock ();
		}
	
		internal void lock_sec_context ()
		{
			debug ("lock sec context");
			mutex_sec_context.@lock ();
		}

		internal void unlock_sec_context ()
		{
			debug ("unlock sec context");
			mutex_sec_context.unlock ();
		}
		
		private void create_pri_thread ()
		{
			try {
				parser_pri_thread = Thread.create (this.parse_pri_contexts, false);
			} catch (ThreadError err) {
				error ("Can't create parser thread: %s", err.message);
			}
		}

		private void create_sec_thread ()
		{
			try {
				parser_sec_thread = Thread.create (this.parse_sec_contexts, false);
			} catch (ThreadError err) {
				error ("Can't create parser thread: %s", err.message);
			}
		}

		public bool add_path_to_vapi_search_dir (string path)
		{
			if (!FileUtils.test (path, FileTest.IS_DIR) || _vapidirs.find_custom (path, GLib.strcmp) != null)
				return false;

			_vapidirs.append (path);
			schedule_parse ();
			return true;
		}

		public bool add_package_from_namespace (string @namespace, bool auto_schedule_parse = true) throws Error
		{
			if (@namespace == null)
				return false;
			var package_name = find_vala_package_name (@namespace);
			return add_package (package_name, auto_schedule_parse);
		}

	
		public void remove_package_from_namespace (string @namespace) throws Error
		{
			var package_name = find_vala_package_name (@namespace);
			remove_package (package_name);
		}

		public void remove_package (string package_name) throws Error
		{
			Gee.List<string> files = find_vala_package_filename (package_name);
			if (list_contains_string (_packages, files[0])) {
				lock_pri_context ();
				files.remove (files[0]);
				unlock_pri_context ();
				schedule_parse ();
			}
		}

		public bool try_add_package (string package_name, bool auto_schedule_parse = true)
		{
			try {
				add_package (package_name, auto_schedule_parse);
				return true;
			} catch (Error err) {
				return false;
			}
		}

	
		public bool add_package (string package_name, bool auto_schedule_parse = true) throws Error
		{
			Gee.List<string> files = find_vala_package_filename (package_name);
			if (files.size > 0) {
				bool need_parse = false;

				lock_pri_context ();
				foreach (string filename in files) {
					if (!list_contains_string (_packages, filename)) {
						_packages.add (filename);
						need_parse = true;
					}
				}
				unlock_pri_context ();
				
				if (need_parse && auto_schedule_parse) {
					debug ("scheduling a parse");
					schedule_parse ();
				}
				return need_parse;
			} else {
				throw new SymbolCompletionError.PACKAGE_FILE_NOT_FOUND ("package file not found");
			}
		}

		public void add_source (string filename) throws Error
		{
			if (FileUtils.test (filename, FileTest.EXISTS)) {
				if (!list_contains_string (_sources, filename)) {
					lock_pri_context ();
					_sources.add (filename);
					unlock_pri_context ();
					
					schedule_parse ();
				}
			} else {
				throw new SymbolCompletionError.PACKAGE_FILE_NOT_FOUND ("source file not found");
			}
		}

		public void remove_source (string filename) throws Error
		{
			if (!list_contains_string (_sources, filename)) {
				lock_pri_context ();
				_sources.remove (filename);
				unlock_pri_context ();
				
				schedule_parse ();
			} else {
				throw new SymbolCompletionError.PACKAGE_FILE_NOT_FOUND ("source file not found");
			}
		}

		public bool contains_source (string filename)
		{
			return list_contains_string (_sources, filename);
		}

		public void add_source_buffer (SourceBuffer source) throws SymbolCompletionError
		{
			if (contains_source_buffer (source))
				throw new SymbolCompletionError.SOURCE_BUFFER ("source already added");

			debug ("added sourcebuffer: %s", source.name);
			lock_sec_context ();
			_source_buffers.add (source);
			unlock_sec_context ();
			
			schedule_parse_source_buffers ();
		}

		public void remove_source_buffer_by_name (string name) throws SymbolCompletionError
		{
			foreach (SourceBuffer item in _source_buffers) {
				if (item.name == name) {
					remove_source_buffer (item);
					return;
				}
			}

			throw new SymbolCompletionError.SOURCE_BUFFER ("source not found");
		}

		public bool contains_source_buffer (SourceBuffer source)
		{
			return contains_source_buffer_by_name (source.name);
		}

		public bool contains_source_buffer_by_name (string name)
		{
			bool result = false;

			lock_sec_context ();
			foreach (SourceBuffer item in _source_buffers) {
				if (item.name == name) {
					result = true;
					break;
				}
			}
			unlock_sec_context ();
			
			return result;
		}

		public void remove_source_buffer (SourceBuffer source)
		{
			lock_sec_context ();
			_source_buffers.add (source);
			unlock_sec_context ();
			
			schedule_parse_source_buffers ();
		}

		public void reparse_source_buffers ()
		{
			schedule_parse_source_buffers ();
		}

		public bool is_cache_building ()
		{
			bool result = false;

			result = need_parse_pri_context > 0 || need_parse_sec_context > 0;
			return result;
		}

		public void reparse (bool all_context)
		{
			schedule_parse_source_buffers ();
			if (all_context) {
				schedule_parse ();
			}
		}

		private void schedule_parse_source_buffers ()
		{
			//scheduling parse for secondary context
			if (AtomicInt.compare_and_exchange (ref need_parse_sec_context, 0, 1)) {
				debug ("PARSE SECONDARY  CONTEXT SCHEDULED, AND THREAD CREATED");
				create_sec_thread ();
			} else {
				debug ("PARSE SECONDARY CONTEXT SCHEDULED");
				AtomicInt.inc (ref need_parse_sec_context);
			}
		}

		private void schedule_parse ()
		{
			//scheduling parse for primary context
 			if (AtomicInt.compare_and_exchange (ref need_parse_pri_context, 0, 1)) {
				debug ("PARSE PRIMARY CONTEXT SCHEDULED, AND THREAD CREATED");
				create_pri_thread ();
			} else {
				debug ("PARSE PRIMARY CONTEXT SCHEDULED");
				AtomicInt.inc (ref need_parse_pri_context);
			}
		}

		private void* parse_pri_contexts ()
		{
			debug ("PARSER THREAD ENTER");
			Gdk.threads_enter ();
			this.cache_building ();
			Gdk.threads_leave ();

			while (true) {
				int stamp = AtomicInt.get (ref need_parse_pri_context);
				debug ("PARSING PRIMARY CONTEXT: START");
				parse ();
				debug ("PARSING PRIMARY CONTEXT: END");
				//check for changes
				if (AtomicInt.compare_and_exchange (ref need_parse_pri_context, stamp, 0)) {
					break;
				}
			}

			Gdk.threads_enter ();
			this.cache_builded ();
			Gdk.threads_leave ();
			debug ("PARSER THREAD EXIT");
			return ((void *) 0);
		}

		private void* parse_sec_contexts ()
		{
			debug ("PARSER SEC THREAD ENTER");
			Gdk.threads_enter ();
			this.cache_building ();
			Gdk.threads_leave ();

			while (true) {
				int stamp = AtomicInt.get (ref need_parse_sec_context);
				debug ("PARSING SEC CONTEXT: START");
				parse_source_buffers ();
				debug ("PARSING SEC CONTEXT: END");
				//check for changes
				if (AtomicInt.compare_and_exchange (ref need_parse_sec_context, stamp, 0)) {
					break;
				}
			}

			Gdk.threads_enter ();
			this.cache_builded ();
			Gdk.threads_leave ();
			debug ("PARSER SEC THREAD EXIT");
			return ((void *) 0);
		}

		private void parse_source_buffers ()
		{
			var current_context = new CodeContext ();
			lock_sec_context ();
			SourceFile source;

			source = new SourceFile (current_context, glib_file, true);
			current_context.add_source_file (source);

			source = new SourceFile (current_context, gobject_file, true);
			current_context.add_source_file (source);
		
			foreach (SourceBuffer src in _source_buffers) {
				if (src.name != null && src.source != null) {
					var name = src.name;

					if (!name.has_suffix (".vala")) {
						name = "%s.vala".printf (name);
					}
					source = new SourceFile (current_context, name, false, src.source);
					source.add_using_directive (new UsingDirective (new UnresolvedSymbol (null, "GLib", null)));
					current_context.add_source_file (source);
				}
			}
			unlock_sec_context ();

			parse_context (current_context);
			bool need_reparse = false;
			//add new namespaces to standard context)
			foreach (SourceFile src in current_context.get_source_files ()) {
				foreach (UsingDirective nr in src.get_using_directives ()) {
					try {
						if (nr.namespace_symbol.name != null && nr.namespace_symbol.name != "") {
							need_reparse = add_package_from_namespace (nr.namespace_symbol.name, false);
						}
					} catch (Error err) {
						warning ("Error adding namespace %s from file %s", nr.namespace_symbol.name, src.filename);
					}
				}
			}

			lock_sec_context ();
			_sec_context = current_context;
			//primary context reparse?
			if (need_reparse) {
				schedule_parse ();
			}
			unlock_sec_context ();
		}

		private void parse ()
		{
			var current_context = new CodeContext ();

			lock_pri_context ();
			SourceFile source;

			source = new SourceFile (current_context, glib_file, true);
			current_context.add_source_file (source);

			source = new SourceFile (current_context, gobject_file, true);
			current_context.add_source_file (source);

			foreach (string item in _packages) {
				if (item != null && item != glib_file && item != gobject_file) {
					debug ("adding package %s", item);					
					source = new SourceFile (current_context, item, true);
					current_context.add_source_file (source);
				}
			}
			foreach (string item in _sources) {
				source = new SourceFile (current_context, item, false);
				source.add_using_directive (new UsingDirective (new UnresolvedSymbol (null, "GLib", null)));
				current_context.add_source_file (source);
			}
			unlock_pri_context ();
			
			parse_context (current_context);
			analyze_context (current_context);

			lock_pri_context ();
			_pri_context = current_context;
			unlock_pri_context ();
		}

		public void parse_context (CodeContext context)
		{
			context.assert = false;
			context.checking = false;
			context.non_null = false;
			context.non_null_experimental = false;
			context.compile_only = true;

			int glib_major = 2;
			int glib_minor = 12;
			context.target_glib_major = glib_major;
			context.target_glib_minor = glib_minor;

			var parser = new Parser ();
			parser.parse (context);
		}

		private void analyze_context (CodeContext context)
		{
			var symbol_resolver = new SymbolResolver ();
			symbol_resolver.resolve (context);

			var semantic = new SemanticAnalyzer ();
			semantic.analyze (context);
		}

		private string? find_vala_package_name (string @namespace) throws GLib.Error
		{
			try {
				//find for: foo.vapi
				//or for: foo-1.0.vapi
				//or for: foo+1.0.vapi
				string[] to_finds = new string[] { "%s.".printf (@namespace.down ()),
								   "%s-".printf (@namespace.down ()),
								   "%s+".printf (@namespace.down ()) };

				foreach (string vapidir in _vapidirs) {
					Dir dir;
					try {					      
						dir = Dir.open (vapidir);
					} catch (FileError err) {
						//do nothing
						continue;
					}
					string? filename = dir.read_name ();
					while (filename != null) {
						if (filename.has_suffix ("vapi")) {
							filename = filename.down ();
							foreach (string to_find in to_finds) {
								if (filename.has_prefix (to_find)) {
									return filename;
								}
							}
						}
						filename = dir.read_name ();
					}
				}
				return null;
			} catch (Error err) {
				throw err;
			}
		}

		private Gee.List<string> find_vala_package_filename (string package_name) throws FileError
		{
			Gee.List<string> results = new Gee.ArrayList<string> ();
			string found_vapidir = null;
			string filename;
			string path;
			if (!package_name.has_suffix (".vapi"))
				filename = "%s.vapi".printf (package_name);
			else
				filename = package_name;

			foreach (string vapidir in _vapidirs) {
				path = "%s/%s".printf (vapidir,filename);

				if (FileUtils.test (path, FileTest.EXISTS)) {
					results.add (path);
					found_vapidir = vapidir;
					break;
				}
			}

			if (results.size > 0) {

				//dependency check
				string dep_file = "%s/%s.deps".printf (found_vapidir, filename.substring (0, filename.length - ".vapi".length));
				if (FileUtils.test (dep_file, FileTest.EXISTS)) {
					size_t len;
					string buffer;
					FileUtils.get_contents (dep_file, out buffer, out len);
					foreach (string dep_name in buffer.split("\n")) {
						if (dep_name.length > 1) {
							var deps = find_vala_package_filename (dep_name);
							foreach (string dep in deps) {
								results.insert (0, dep);
							}
						}
					}
				}
			}
			return results;
		}
	
		private bool list_contains_string (Gee.List<string> list, string @value)
		{
			foreach (string current in list) {
				if (current == @value)
					return true;
			}

			return false;
		}		
	}
}