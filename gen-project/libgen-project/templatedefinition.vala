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
	public class TemplateDefinition
	{
		public string version { get; private set; }
		public string name { get; private set; default = null; }
		public string description { get; private set; }
		public string details { get; private set; }
		public string language { get; private set; }
		public string build_system { get; private set; }
		public List<string> tags { get { return _tags; } }
		public string icon_filename { get; private set; default = null; }
		
		private string _filename;
		private List<string> _tags = new List<string> ();
		
		public TemplateDefinition (string filename)
		{
			this._filename = filename;
			load ();
		}
		
		private void load ()
		{
			try {
				var file = new KeyFile ();
				file.load_from_file (_filename, KeyFileFlags.NONE);
				if (file.has_group ("Template") && file.has_key ("Template", "name")) {
					this.version = read_key (file, "version");
					this.name = read_key (file, "name");
					this.description = read_key (file, "description", "");
					this.details = read_key (file, "details", "");
					this.language = read_key (file, "language", "");
					this.build_system = read_key (file, "build-system", "");
					var tmp = read_key (file, "tags", "").split (",");
				
					foreach (string tag in tmp) {
						_tags.append (tag.strip ());
					}
				
					icon_filename = Path.build_filename (Path.get_dirname (_filename), Path.get_basename (_filename).replace (".ini", ".png"));
					if (!FileUtils.test (icon_filename, FileTest.IS_REGULAR))
						icon_filename = null; // no icon file founds
				}
			} catch (Error err) {
				warning ("error loading keyfile %s: %s", _filename, err.message);
			}
		}
		
		private string read_key (KeyFile file, string key_name, string? default_value = null) throws KeyFileError
		{
			if (file.has_key ("Template", key_name)) {
				return file.get_string ("Template", key_name).strip ();
			} else {
				return default_value;
			}
		}
	}
}
