/* parser.vala
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
	private class Cache : GLib.Object
	{
		public string path;
		public double time;
		public CodeContext context;
	}

	internal static Mutex cache_mutex = null;
	internal static Gee.List<Cache> context_cache ;
	internal const int CACHE_SIZE = 10;
	
	public void initialize_cache ()
	{
		if (cache_mutex == null) {
			Afrodite.cache_mutex = new Mutex ();
			context_cache = new Gee.ArrayList<Cache> ();
		}
	}
	
	public class Parser : GLib.Object
	{
		private Gee.List<SourceItem> _sources;
		public Vala.SourceFile source_file;
		public CodeContext context = null;
		
		public Parser (Gee.List<SourceItem> sources)
		{
			_sources = sources;
		}
		
		private void parse_old ()
		{
//			debug ("parser class, start parsing: %s", _source.path);
			/*
			foreach (SourceItem source in _sources) {
				// first try to find it in cache
				cache_mutex.@lock ();
	 			foreach (Cache item in context_cache) {
	 				if (item.path == _source.path) {
	 					context = item.context;
	 					debug ("parser: cache hit %s", item.path);
	 					break;
	 				}
	 			}
	 			cache_mutex.unlock ();

 			}
 			*/
 			
 			/*
 			cache_mutex.@lock ();
			if (context_cache.size < CACHE_SIZE) {
				bool found = false;
				
 				foreach (Cache item in context_cache) {
 					if (item.path == _source.path) {
 						found = true;
 						break;
 					}
 				}
 				
 				if (!found) {
					var item = new Cache ();
					item.time = time;
					item.context = context;
					item.path = _source.path;
					context_cache.add (item);
					debug ("parser: caching %s", item.path);
				}
			} else {
				foreach (Cache item in context_cache) {
					if (item.time < time && item.path != _source.path) {
						item.time = time;
						item.context = context;
						item.path = _source.path;
						debug ("parser: caching %s", item.path);
						break;
					}
				}
			}
			cache_mutex.unlock ();		
			*/
			
		}
		
		public void parse ()
		{
			context = new Vala.CodeContext();
			CodeContext.push (context);
			bool has_glib = false;
			foreach (SourceItem source in _sources) {
				if (source.is_glib) {
					has_glib = true;
					break;
				}
			}
			if (!has_glib) {
				if (!Utils.add_package ("glib-2.0", context))
					GLib.error ("failed to add GLib 2.0");
			
				if (!Utils.add_package ("gobject-2.0", context))
					GLib.error ("failed to add GObject 2.0");
			}			
			foreach (SourceItem source in _sources) {
				if (source.content == null) 
					source_file = new Vala.SourceFile (context, source.path, source.is_vapi); // normal source
				else
					source_file = new Vala.SourceFile (context, source.path, source.is_vapi, source.content); // live buffer
				var ns_ref = new UsingDirective (new UnresolvedSymbol (null, "GLib", null));
				context.root.add_using_directive (ns_ref);
				context.add_source_file (source_file);
				source_file.add_using_directive (ns_ref);
			}
						
			context.assert = false;
			context.checking = false;
			context.non_null_experimental = false;
			context.compile_only = true;

			context.profile = Profile.GOBJECT;
			context.add_define ("GOBJECT");
			context.add_define ("VALA_0_7_6_NEW_METHODS");
			
			int glib_major = 2;
			int glib_minor = 12;
			context.target_glib_major = glib_major;
			context.target_glib_minor = glib_minor;
			
			var parser = new Vala.Parser ();
			var timer = new Timer ();
			timer.start ();
			parser.parse (context);
			timer.stop ();
			
			// update the cache with top most expensive parsing
			double time = timer.elapsed ();
			

			
			CodeContext.pop ();
		}		
	}
}
