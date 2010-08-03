/* templatedefinition.vala
 *
 * Copyright (C) 2007-2010  Andrea Del Signore
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Andrea Del Signore <sejerpz@tin.it>
 */

using GLib;

namespace GenProject
{
	public class TemplateDefinition : Object
	{
		public int id { get; internal set; }
		public string version { get; private set; }
		public string name { get; private set; default = null; }
		public string description { get; private set; }
		public string details { get; private set; }
		public string language { get; private set; }
		public string build_system { get; private set; }
		public List<string> tags { get { return _tags; } }
		public string icon_filename { get; private set; default = null; }
		public string archive_filename { get; private set; default = null; }
		
		private string _filename;
		private List<string> _tags = new List<string> ();
		
		private TemplateDefinition ()
		{
		}
		
		public static TemplateDefinition? load (string filename)
		{
			TemplateDefinition result = null;
			try {
				var file = new KeyFile ();
				file.load_from_file (filename, KeyFileFlags.NONE);
				if (file.has_group ("Template") && file.has_key ("Template", "name")) {
					result = new TemplateDefinition ();			
					result._filename = filename;
					result.version = read_key (file, "version");
					result.name = read_key (file, "name");
					result.description = read_key (file, "description", "");
					result.details = read_key (file, "details", "");
					result.language = read_key (file, "language", "");
					result.build_system = read_key (file, "build-system", "");
					var tmp = read_key (file, "tags", "").split (",");
				
					foreach (string tag in tmp) {
						result._tags.append (tag.strip ());
					}
				
					result.icon_filename = Path.build_filename (Path.get_dirname (filename), Path.get_basename (filename).replace (".ini", ".png"));
					if (!FileUtils.test (result.icon_filename, FileTest.IS_REGULAR)) {
						message ("no icon found for project: %s", result.icon_filename);
						result.icon_filename = null; // no icon file founds
					}
					result.archive_filename = Path.build_filename (Path.get_dirname (filename), Path.get_basename (filename).replace (".ini", ".tar.gz"));
					if (!FileUtils.test (result.archive_filename, FileTest.IS_REGULAR)) {
						critical ("no archive found for project: %s", result.archive_filename);
						result.archive_filename = null; // template archive file founds
					}
				}
			} catch (Error err) {
				warning ("error loading keyfile %s: %s", filename, err.message);
			}
			return result;
		}
		
		private static string read_key (KeyFile file, string key_name, string? default_value = null) throws KeyFileError
		{
			if (file.has_key ("Template", key_name)) {
				return file.get_string ("Template", key_name).strip ();
			} else {
				return default_value;
			}
		}
	}
}
