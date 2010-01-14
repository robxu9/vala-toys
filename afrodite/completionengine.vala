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
		
		private Vala.List<string> vapidirs;
		private Vala.List<SourceItem> source_queue;
		private Vala.List<SourceItem> merge_queue;
		
		private Mutex source_queue_mutex;
		private Mutex merge_queue_mutex;
		private Mutex ast_mutex = null;
		
		private unowned Thread parser_thread;
		private int parser_stamp = 0;
		private int parser_remaining_files = 0;
		
		private Ast _ast;
		
		public CompletionEngine (string? id = null)
		{
			if (id == null)
				id = "";
				
			this.id = id;
			vapidirs = new ArrayList<string> (GLib.str_equal);
			source_queue = new ArrayList<SourceItem> ();
			merge_queue = new ArrayList<SourceItem> ();
			source_queue_mutex = new Mutex ();
			merge_queue_mutex = new Mutex ();
			
			_ast = new Ast ();
			// merge standard base vapi (glib and gobject)
			var context = new CodeContext ();
			ast_mutex = new Mutex ();
			
			string[] packages = new string[] { "glib-2.0", "gobject-2.0" };
			foreach (string package in packages) {
				var paths = Utils.get_package_paths (package, context);
				if (paths != null)
					queue_sourcefiles (paths, null, true, true);
			}
			
		}
		
		~Completion ()
		{
			ast_mutex.lock ();
			_ast = null;
			ast_mutex.unlock ();
			if (AtomicInt.@get (ref parser_stamp) != 0)
				parser_thread.join ();

			parser_thread = null;
		}

		public bool is_parsing
		{
			get {
				return AtomicInt.@get (ref parser_stamp) != 0;
			}
		}

		public void add_vapi_dir (string path)
		{
			vapidirs.add (path);
		}
		
		public void remove_vapi_dir (string path)
		{
			if (!vapidirs.remove (path))
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
			foreach (SourceItem source in source_queue) {
 				if (source.path == value.path) {
 					return source;
 				}
			}
			
			return null;
		}

		public void queue_sources (Vala.List<SourceItem> sources)
		{
			source_queue_mutex.@lock ();
			foreach (SourceItem source in sources) {
				var item = source_queue_contains (source);
				if (item == null || item.content != source.content) {
				/*
					if (source.content == null || source.content == "")
						debug ("%s: queued source %s. sources to parse %d", id, source.path, source_queue.size);
					else
						debug ("%s: queued live buffer %s. sources to parse %d", id, source.path, source_queue.size);
				*/	
					if (item != null)
						source_queue.remove (item);

					source_queue.add (source.copy ());
				} 
				else if (item.content == null && source.content != null) {
					item.content = source.content;
					//debug ("%s: updated live buffer %s. sources to parse %d", id, source.path, source_queue.size);
				}
			}
			source_queue_mutex.@unlock ();
			
			if (AtomicInt.compare_and_exchange (ref parser_stamp, 0, 1)) {
				create_parser_thread ();
			} else {
				AtomicInt.inc (ref parser_stamp);
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
				item.is_vapi = is_vapi;
				item.is_glib = is_glib;
				sources.add (item);
			}
			
			queue_sources (sources);
		}
		
		public bool try_acquire_ast (out Ast ast)
		{
			bool res = false;
			ast = null;
			int retry = 0;
			
			while (ast == null && ast_mutex != null && retry < 20 && AtomicInt.get (ref parser_remaining_files) < 3)
			{
				res = ast_mutex.@trylock ();

				if (res) {
					ast = _ast;
				} else {
					GLib.Thread.usleep (100 * 1000);
					retry++;
				}
			}

			return res;
		}
		
		public void release_ast (Ast ast)
		{
			if (_ast != ast) {
				warning ("%s: release_ast requested for unknown ast instance", id);
				return;
			}
			
			ast_mutex.unlock ();
		}

		private void create_parser_thread ()
		{				
			try {
				if (parser_thread != null) {
					parser_thread.join ();
				}
				parser_thread = Thread.create_full (this.parse_sources, 0, true, false, ThreadPriority.LOW);
			} catch (ThreadError err) {
				error ("%s: can't create parser thread: %s", id, err.message);
			}
		}
		
		private void* parse_sources ()
		{
			GLib.Timer timer = new GLib.Timer ();
			timer.start ();
			debug ("%s: parser thread starting...", id);
			begin_parsing (this);
			Vala.List<SourceItem> sources = new ArrayList<SourceItem> ();
			
			while (true) {
				int stamp = AtomicInt.get (ref parser_stamp);
				
				// get the source to parse
				source_queue_mutex.@lock ();
				int source_count = source_queue.size;
				foreach (SourceItem item in source_queue) {
					sources.add (item.copy ());
				}
				source_queue.clear ();
				source_queue_mutex.@unlock ();

				Parser p = new Parser (sources);
				p.parse ();
				
				
				// do the actual merging
				// set the number of sources to process
				AtomicInt.set (ref parser_remaining_files, sources.size);
				ast_mutex.@lock ();
				if (_ast != null) {
					var merger = new AstMerger (_ast);
					foreach (SourceItem source in sources) {
						source.context = p.context;
					
						if (source.context == null)
							critical ("source %s context == null, non thread safe access to source item", source.path);
						else {
							foreach (Vala.SourceFile s in source.context.get_source_files ()) {
								if (s.filename == source.path) {
									bool source_exists = _ast.lookup_source_file (source.path) != null;
								
									// if I'm parsing just one source and there are errors and the source already
									// exists in the ast, I'll keep the previous copy
									if (source_count == 1 && source_exists && p.context.report.get_errors () > 0)
										break;
									
									if (source_exists) {
										//debug ("%s: removing %s", id, source.path);
										merger.remove_source_filename (source.path);
									}
								
									//timer.start ();
									merger.merge_vala_context (s, source.context, source.is_glib);
									//timer.stop ();
									//debug ("%s: merging context and file %s in %g", id, s.filename, timer.elapsed ());
									break;
								}
							}
						}
					
						AtomicInt.add (ref parser_remaining_files, -1);
					}
					var resolver = new SymbolResolver ();
					resolver.resolve (_ast);
				}
				ast_mutex.unlock ();
				
				sources.clear ();
				
				//check for changes
				if (AtomicInt.compare_and_exchange (ref parser_stamp, stamp, 0)) {
					break;
				}
 			}
			// clean up and exit
			sources = null;
			
			timer.stop ();
			debug ("%s: parser thread exiting (elapsed time %g)...", id, timer.elapsed ());
			end_parsing (this);
			return null;
		}
	}
}
