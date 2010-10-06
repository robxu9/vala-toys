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
	public class Parser : GLib.Object
	{
		public CodeContext context = null;

		public Parser (Vala.List<SourceItem> sources)
		{
			context = new Vala.CodeContext();
			foreach (SourceItem source in sources) {
				add_source_item (source);
			}

		}

		public Parser.with_source (SourceItem source_item)
		{
			context = new Vala.CodeContext();
			add_source_item (source_item);
		}

		private void add_source_item (SourceItem source)
		{
			Vala.SourceFile source_file = null;
			
			if (source.content == null && !FileUtils.test (source.path, FileTest.EXISTS)) {
				warning ("file %s not exists", source.path);
				return;
			}
			if (source.content == null) 
				source_file = new Vala.SourceFile (context, source.is_vapi ? SourceFileType.PACKAGE : SourceFileType.SOURCE, source.path); // normal source
			else if (source.content != "") {
				source_file = new Vala.SourceFile (context, source.is_vapi ? SourceFileType.PACKAGE : SourceFileType.SOURCE, source.path, source.content); // live buffer
				//Utils.trace ("queue live buffer %s:\n%s\n", source.path, source.content);
			} else {
				warning ("sourcefile %s with empty content not queued", source.path);
			}
			
			if (source_file != null) {
				var ns_ref = new UsingDirective (new UnresolvedSymbol (null, "GLib", null));
				if (!source.is_glib)
					context.root.add_using_directive (ns_ref);
				
				context.add_source_file (source_file);
				if (!source.is_glib)
					source_file.add_using_directive (ns_ref);
			}
		}

		public ParseResult parse ()
		{
			var parse_result = new ParseResult ();
			CodeContext.push (context);
			context.assert = false;
			context.checking = false;
			context.experimental = false;
			context.experimental_non_null = false;
			context.compile_only = true;
			context.report = parse_result;
			context.profile = Profile.GOBJECT;
			context.add_define ("GOBJECT");

			int glib_major = 2;
			int glib_minor = 14;
			context.target_glib_major = glib_major;
			context.target_glib_minor = glib_minor;

			for (int i = 2; i <= 12; i += 2) {
				context.add_define ("VALA_0_%d".printf (i));
			}

			for (int i = 16; i <= glib_minor; i += 2) {
				context.add_define ("GLIB_2_%d".printf (i));
			}

			var parser = new Vala.Parser ();
			parser.parse (context);

			CodeContext.pop ();
			return parse_result;
		}
	}
}
