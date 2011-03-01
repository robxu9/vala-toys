/* sourcereference.vala
 *
 * Copyright (C) 2009  Andrea Del Signore
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 * 	Andrea Del Signore <sejerpz@tin.it>
 */

using GLib;
using Vala;

namespace Afrodite
{
	public class CompletionEngine : Object
	{
		public string id;
		public signal void begin_parsing (CompletionEngine sender);
		public signal void end_parsing (CompletionEngine sender);
		public signal void file_parsed (CompletionEngine sender, string filename, ParseResult parse_result);

		private Vala.List<string> _vapidirs;
		private Vala.List<SourceItem> _source_queue;
		private Vala.List<SourceItem> _merge_queue;
		
		private Mutex _source_queue_mutex;
		private Mutex _merge_queue_mutex;
		
		private unowned Thread<int> _parser_thread;
		private int _parser_stamp = 0;
		private int _parser_remaining_files = 0;
		private int _current_parsing_total_file_count = 0;
		private bool _glib_init = false;
		
		private Ast _ast;
		private Vala.List<ParseResult> _parse_result_list = new Vala.ArrayList<ParseResult> ();
		private uint _idle_id = 0;

		public CompletionEngine (string? id = null)
		{
			if (id == null)
				id = "";
				
			this.id = id;
			_vapidirs = new ArrayList<string> (GLib.str_equal);
			_source_queue = new ArrayList<SourceItem> ();
			_merge_queue = new ArrayList<SourceItem> ();
			_source_queue_mutex = new Mutex ();
			_merge_queue_mutex = new Mutex ();
			
			_ast = new Ast ();
		}
		
		~Completion ()
		{
			Utils.trace ("Completion %s destroy", id);
			// invalidate the ast so the parser thread will exit asap
			_ast = null;

			if (AtomicInt.@get (ref _parser_stamp) != 0) {
				Utils.trace ("join the parser thread before exit");
				_parser_thread.join ();
			}
			_parser_thread = null;
			if (_idle_id != 0) {
				Source.remove (_idle_id);
				_idle_id = 0;
			}
			Utils.trace ("Completion %s destroyed", id);
		}

		public bool is_parsing
		{
			get {
				return AtomicInt.@get (ref _parser_stamp) != 0;
			}
		}

		public void add_vapi_dir (string path)
		{
			_vapidirs.add (path);
		}
		
		public void remove_vapi_dir (string path)
		{
			if (!_vapidirs.remove (path))
				warning ("remove_vapi_dir: vapidir %s not found", path);
		}
		
		public void queue_source (SourceItem item)
		{
			var sources = new ArrayList<SourceItem> ();
			sources.add (item.copy ());
			queue_sources (sources);
		}

		private SourceItem? source_queue_contains (SourceItem value)
		{
			foreach (SourceItem source in _source_queue) {
 				if (source.path == value.path) {
 					return source;
 				}
			}
			
			return null;
		}

		public bool queue_sources (Vala.List<SourceItem> sources, bool no_update_check = false)
		{
			bool result = false;
			
			_source_queue_mutex.@lock ();
			if (!_glib_init) {
				// merge standard base vapi (glib and gobject)
				_glib_init = true;
				string[] packages = new string[] { "glib-2.0", "gobject-2.0" };
				var context = new CodeContext ();
				
				foreach (string package in packages) {
					var paths = Utils.get_package_paths (package, context);
					if (paths != null) {
						foreach (string path in paths) {
							var item = new SourceItem ();
							item.path = path;
							item.content = null;
							item.is_glib = true;
							sources.insert (0, item);
						}
					}
				}
			}
			foreach (SourceItem source in sources) {
				bool skip_unchanged_file = false;

				// test if file is really changed but only if it's not a live buffer
				if (no_update_check == false && source.content == null && _ast != null) {
					var sf = _ast.lookup_source_file (source.path);
					if (sf != null && sf.update_last_modification_time ()) {
						Utils.trace ("engine %s: skip unchanged source %s", id, source.path);
						skip_unchanged_file = true;
					}
				}

				if (!skip_unchanged_file)
				{
					var item = source_queue_contains (source);
					if (item == null || item.content != source.content) {
					/*
						if (source.content == null || source.content == "")
							Utils.trace ("%s: queued source %s. sources to parse %d", id, source.path, source_queue.size);
						else
							Utils.trace ("%s: queued live buffer %s. sources to parse %d", id, source.path, source_queue.size);
					*/	
						if (item != null)
							_source_queue.remove (item);

						_source_queue.add (source.copy ());
					} 
					else if (item.content == null && source.content != null) {
						item.content = source.content;
						//Utils.trace ("%s: updated live buffer %s. sources to parse %d", id, source.path, source_queue.size);
					}
				}
			}
			_source_queue_mutex.@unlock ();
			
			if (AtomicInt.compare_and_exchange (ref _parser_stamp, 0, 1)) {
				create_parser_thread ();
			} else {
				AtomicInt.inc (ref _parser_stamp);
			}
			
			return result;
		}
		
		public void queue_sourcefile (string path, string? content = null, bool is_vapi = false, bool is_glib = false)
		{
			var sources = new ArrayList<string> ();
			sources.add (path);
			
			queue_sourcefiles (sources, content, is_vapi);
		}

		public void queue_sourcefiles (Vala.List<string> paths, string? content = null, bool is_vapi = false, bool is_glib = false)
		{
			var sources = new ArrayList<SourceItem> ();
			
			foreach (string path in paths) {
				var item = new SourceItem ();
				item.path = path;
				item.content = content;
				item.is_glib = is_glib;
				sources.add (item);
			}
			
			queue_sources (sources);
		}
		
		public bool try_acquire_ast (out Ast ast, int retry_count = -1)
		{
			// this method is a NO-OP
			ast = _ast;
			return true;
		}
		

		
		public void release_ast (Ast ast)
		{
			// this method is a NO-OP
		}

		private void create_parser_thread ()
		{				
			try {
				if (_parser_thread != null) {
					_parser_thread.join<int> ();
				}
				_parser_thread = Thread.create_full<int> (this.parse_sources, 0, true, false, ThreadPriority.LOW);
			} catch (ThreadError err) {
				error ("%s: can't create parser thread: %s", id, err.message);
			}
		}

		private int parse_sources ()
		{
#if DEBUG
			GLib.Timer timer = new GLib.Timer ();
			double start_parsing_time = 0;
			double parsing_time = 0;
			double start_time = 0;
			timer.start ();
#endif
			Utils.trace ("engine %s: parser thread *** starting ***...", id);
			begin_parsing (this);
			Vala.List<SourceItem> sources = new ArrayList<SourceItem> ();

			while (true) {
#if DEBUG
				start_parsing_time = timer.elapsed ();
#endif
				int stamp = AtomicInt.get (ref _parser_stamp);
				// set the number of sources to process
				AtomicInt.set (ref _parser_remaining_files, _source_queue.size );
				// get the source to parse
				_source_queue_mutex.@lock ();
				foreach (SourceItem item in _source_queue) {
					sources.add (item.copy ());
				}

				Utils.trace ("engine %s: queued %d", id, sources.size);
				AtomicInt.set (ref _current_parsing_total_file_count, sources.size);
				
				_source_queue.clear ();
				_source_queue_mutex.@unlock ();

				foreach (SourceItem source in sources) {
#if DEBUG
					Utils.trace ("engine %s: parsing source: %s", id, source.path);
					start_time = timer.elapsed ();
#endif

					Parser p = new Parser.with_source (source);
					var parse_results = p.parse ();
					lock (_parse_result_list) {
						_parse_result_list.add (parse_results);
						if (_idle_id == 0)
							_idle_id = Idle.add_full (Priority.DEFAULT_IDLE, on_parse_results);
					}
#if DEBUG
					Utils.trace ("engine %s: parsing source: %s done %g", id, source.path, timer.elapsed () - start_time);
#endif
					AtomicInt.add (ref _parser_remaining_files, -1);
				}
#if DEBUG
				parsing_time += (timer.elapsed () - start_parsing_time);
#endif

				sources.clear ();

				//check for changes or exit request
				if (_ast == null || AtomicInt.compare_and_exchange (ref _parser_stamp, stamp, 0)) {
					break;
				}
			}

			// clean up and exit
			AtomicInt.set (ref _current_parsing_total_file_count, 0);
			sources = null;

#if DEBUG
			timer.stop ();
			Utils.trace ("engine %s: parser thread *** exiting *** (elapsed time parsing %g, resolving %g)...", id, parsing_time, timer.elapsed ());
#endif
			end_parsing (this);
			return 0;
		}

		private bool on_parse_results ()
		{
			bool more_results = true;
			string filename = null;
			ParseResult result = null;
#if DEBUG
			GLib.Timer timer = new GLib.Timer ();
			double start_time = 0;
			timer.start ();
#endif

			lock (_parse_result_list) {
				if (_parse_result_list.size > 0) {
					foreach (ParseResult key in _parse_result_list) {
						result = key;
						_parse_result_list.remove (key);
						filename = key.source.path;
						break; // one iteration
					}
				}
				if (_parse_result_list.size == 0) {
					_idle_id = 0;
					more_results = false;
				}
			}
			if (result != null) {
				foreach (Vala.SourceFile s in result.source.context.get_source_files ()) {
					if (s.filename == result.source.path) {
						bool source_exists = _ast.lookup_source_file (result.source.path) != null;
						var merger = new AstMerger (_ast);
						if (source_exists) {
#if DEBUG
							Utils.trace ("engine %s: removing source %s", id, result.source.path);
							start_time = timer.elapsed ();
#endif
							merger.remove_source_filename (result.source.path);
#if DEBUG
							Utils.trace ("engine %s: removing source %s done %g", id, result.source.path, timer.elapsed () - start_time);
#endif

						}
#if DEBUG
						Utils.trace ("engine %s: merging source %s", id, result.source.path);
						start_time = timer.elapsed ();
#endif
						merger.merge_vala_context (s, result.source.context, result.source.is_glib);
						result.source.context = null; // let's free some memory
#if DEBUG
						Utils.trace ("engine %s: merging source %s done %g", id, result.source.path, timer.elapsed () - start_time);
#endif

#if DEBUG
						//_ast.dump_symbols ();
						Utils.trace ("engine %s: resolving ast", id);
						start_time = timer.elapsed ();
#endif
						var resolver = new SymbolResolver ();
						resolver.resolve (_ast);
#if DEBUG
						Utils.trace ("engine %s: resolving ast done %g", id, timer.elapsed () - start_time);
#endif
						break; // found the file
					}
				}
				this.file_parsed (this, filename, result);
			}
			return more_results;
		}
	}
}
