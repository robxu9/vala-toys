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
		
		private Vala.List<string> _vapidirs;
		private Vala.List<SourceItem> _source_queue;
		private Vala.List<SourceItem> _merge_queue;
		
		private Mutex _source_queue_mutex;
		private Mutex _merge_queue_mutex;
		private Mutex _ast_mutex = null;
		
		private unowned Thread _parser_thread;
		private int _parser_stamp = 0;
		private int _parser_remaining_files = 0;
		private int _current_parsing_total_file_count = 0;
		private bool _glib_init = false;
		
		private Ast _ast;
		
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
			_ast_mutex = new Mutex ();
		}
		
		~Completion ()
		{
			Utils.trace ("Completion %s destroy", id);
			// invalidate the ast so the parser thread will exit asap
			_ast_mutex.lock ();
			_ast = null;
			_ast_mutex.unlock ();

			if (AtomicInt.@get (ref _parser_stamp) != 0) {
				Utils.trace ("join the parser thread before exit");
				_parser_thread.join ();
			}
			_parser_thread = null;
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

		public void queue_sources (Vala.List<SourceItem> sources)
		{
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
			_source_queue_mutex.@unlock ();
			
			if (AtomicInt.compare_and_exchange (ref _parser_stamp, 0, 1)) {
				create_parser_thread ();
			} else {
				AtomicInt.inc (ref _parser_stamp);
			}		
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
			bool res = false;
			ast = null;
			bool first_run = true;
			int file_count = 0;
			int retry = 0;
			
			while (ast == null 
				&& _ast_mutex != null 
				&& (first_run || (file_count = AtomicInt.get (ref _current_parsing_total_file_count)) <= 2))
			{
				first_run = false;
				res = _ast_mutex.@trylock ();
				if (res) {
					ast = _ast;
				} else {
					if (retry_count < 0 || retry < retry_count) {
						retry++;
						GLib.Thread.usleep (100 * 1000);
					} else {
						break;
					}
				}
			}

#if DEBUG
			if (ast == null) {
				//Utils.trace ("can't acquire lock: %d", file_count);
			} else {
				Utils.trace ("lock acquired: %d", file_count);
			}
#endif

			return res;
		}
		
		public void release_ast (Ast ast)
		{
			if (_ast != ast) {
				warning ("%s: release_ast requested for unknown ast instance", id);
				return;
			}
			
			_ast_mutex.unlock ();
		}

		private void create_parser_thread ()
		{				
			try {
				if (_parser_thread != null) {
					_parser_thread.join ();
				}
				_parser_thread = Thread.create_full (this.parse_sources, 0, true, false, ThreadPriority.LOW);
			} catch (ThreadError err) {
				error ("%s: can't create parser thread: %s", id, err.message);
			}
		}

/*
		private void* parse_sources_old ()
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
				// set the number of sources to process + 1, because the last one
				// will be decreased by the resolve part
				AtomicInt.set (ref _parser_remaining_files, _source_queue.size + 1);
				// get the source to parse
				_source_queue_mutex.@lock ();
				int source_count = _source_queue.size;
				foreach (SourceItem item in _source_queue) {
					sources.add (item.copy ());
				}
				
				//GLib.debug ("queued %d", sources.size);
				AtomicInt.set (ref _current_parsing_total_file_count, sources.size);
				
				_source_queue.clear ();
				_source_queue_mutex.@unlock ();

#if DEBUG
				Utils.trace ("engine %s: parsing sources: %d", id, sources.size);
				timer.stop ();
				start_time = timer.elapsed ();
				timer.start ();
#endif

				Parser p = new Parser (sources);
				p.parse ();
#if DEBUG
				Utils.trace ("engine %s: parsing sources %d done %g", id, sources.size, timer.elapsed () - start_time);
#endif

				AstMerger merger = null;
				foreach (SourceItem source in sources) {
					source.context = p.context;
				
					if (source.context == null)
						critical ("source %s context == null, non thread safe access to source item", source.path);
					else {
						foreach (Vala.SourceFile s in source.context.get_source_files ()) {
							if (s.filename == source.path) {
								// do the real merge
								_ast_mutex.@lock ();
								if (_ast != null) {
									bool source_exists = _ast.lookup_source_file (source.path) != null;

									// if the ast is still valid: not null
									// and not 
									// if I'm parsing just one source and there are errors and the source already exists in the ast: I'll keep the previous copy
									// do the merge
								
									if (!(source_count == 1 && source_exists && p.context.report.get_errors () > 0)) {
										if (merger == null) {
											// lazy init the merger, here I'm sure that _ast != null
											merger = new AstMerger (_ast);
										}
										if (source_exists) {
											merger.remove_source_filename (source.path);
										}
							
#if DEBUG
										Utils.trace ("engine %s: merging source %s", id, source.path);
										timer.stop ();
										start_time = timer.elapsed ();
										timer.start ();
#endif
										merger.merge_vala_context (s, source.context, source.is_glib);
#if DEBUG
										Utils.trace ("engine %s: merging source %s done %g", id, source.path, timer.elapsed () - start_time);
#endif

									}
								}
								_ast_mutex.unlock ();
								
								//timer.stop ();
								//debug ("%s: merging context and file %s in %g", id, s.filename, timer.elapsed ());
								break;
							}
						}
					}
					AtomicInt.add (ref _parser_remaining_files, -1);
				}

#if DEBUG
				timer.stop ();
				parsing_time += start_parsing_time - timer.elapsed ();
#endif
				_ast_mutex.@lock ();
				if (_ast != null) {
#if DEBUG
					Utils.trace ("engine %s: resolving ast", id);
					timer.stop ();
					start_time = timer.elapsed ();
					timer.start ();
#endif

					var resolver = new SymbolResolver ();
					resolver.resolve (_ast);
#if DEBUG
					Utils.trace ("engine %s: resolving ast done %g", id, timer.elapsed () - start_time);
#endif
				}
				AtomicInt.add (ref _parser_remaining_files, -1);
				_ast_mutex.unlock ();
				
				
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
			return null;
		}
*/

		private void* parse_sources ()
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
				// set the number of sources to process + 1, because the last one
				// will be decreased by the resolve part
				AtomicInt.set (ref _parser_remaining_files, _source_queue.size + 1);
				// get the source to parse
				_source_queue_mutex.@lock ();
				int source_count = _source_queue.size;
				foreach (SourceItem item in _source_queue) {
					sources.add (item.copy ());
				}

				Utils.trace ("engine %s: queued %d", id, sources.size);
				AtomicInt.set (ref _current_parsing_total_file_count, sources.size);
				
				_source_queue.clear ();
				_source_queue_mutex.@unlock ();

				AstMerger merger = null;
				foreach (SourceItem source in sources) {
#if DEBUG
					Utils.trace ("engine %s: parsing source: %s", id, source.path);
					timer.stop ();
					start_time = timer.elapsed ();
					timer.start ();
#endif

					Parser p = new Parser.with_source (source);
					p.parse ();
#if DEBUG
					Utils.trace ("engine %s: parsing source %s done %g", id, source.path, timer.elapsed () - start_time);
#endif
					source.context = p.context;
				
					if (source.context == null)
						critical ("source %s context == null, non thread safe access to source item", source.path);
					else {
						foreach (Vala.SourceFile s in source.context.get_source_files ()) {
							if (s.filename == source.path) {
								// do the real merge
								_ast_mutex.@lock ();
								if (_ast != null) {
									bool source_exists = _ast.lookup_source_file (source.path) != null;

									// if the ast is still valid: not null
									// and not 
									// if I'm parsing just one source and there are errors and the source already exists in the ast: I'll keep the previous copy
									// do the merge
								
									if (!(source_count == 1 && source_exists && p.context.report.get_errors () > 0)) {
										if (merger == null) {
											// lazy init the merger, here I'm sure that _ast != null
											merger = new AstMerger (_ast);
										}
										if (source_exists) {
											merger.remove_source_filename (source.path);
										}
#if DEBUG
										Utils.trace ("engine %s: merging source %s", id, source.path);
										timer.stop ();
										start_time = timer.elapsed ();
										timer.start ();
#endif
										merger.merge_vala_context (s, source.context, source.is_glib);
#if DEBUG
										Utils.trace ("engine %s: merging source %s done %g", id, source.path, timer.elapsed () - start_time);
#endif
									}
								}
								_ast_mutex.unlock ();
								
								//timer.stop ();
								//debug ("%s: merging context and file %s in %g", id, s.filename, timer.elapsed ());
								break;
							}
						}
					}
					AtomicInt.add (ref _parser_remaining_files, -1);
				}
#if DEBUG
				timer.stop ();
				parsing_time += start_parsing_time - timer.elapsed ();
#endif

				_ast_mutex.@lock ();
				if (_ast != null) {
#if DEBUG
					Utils.trace ("engine %s: resolving ast", id);
					timer.stop ();
					start_time = timer.elapsed ();
					timer.start ();
#endif
					var resolver = new SymbolResolver ();
					resolver.resolve (_ast);
#if DEBUG
					Utils.trace ("engine %s: resolving ast done %g", id, timer.elapsed () - start_time);
#endif
				}
				AtomicInt.add (ref _parser_remaining_files, -1);
				_ast_mutex.unlock ();
				
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
			return null;
		}
	}
}
