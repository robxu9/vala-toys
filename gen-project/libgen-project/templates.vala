/* templates.vala
 *
 * Copyright (C) 2010  Andrea Del Signore
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
 	public class Templates : Object
 	{
 		private List<TemplateDefinition> _definitions = new List<TemplateDefinition> ();
 		private int _next_id = 0;
 		
 		private Templates ()
 		{
 			
 		}
 
 		public List<TemplateDefinition> definitions { get { return _definitions; } }
 				
 		public static Templates load (string[]? user_path = null)
 		{
 			var result = new Templates ();
 			
 			string[] standard_path = new string[] {
 				Path.build_filename (Config.PACKAGE_DATADIR, "templates"),
 				Path.build_filename (Environment.get_user_data_dir (), "gen-project", "templates")
 			};
 			
 			foreach (string path in standard_path) {
 				debug ("scanning directory %s for templates", path);
 				result.scan_path (path);
 				
 			}
 			
 			if (user_path != null) {
	 			foreach (string path in user_path) {
	 				debug ("scanning user directory %s for templates", path);
	 				result.scan_path (path);
	 			}
 			}
 			
 			return result;
 		}
 		
 		private void scan_path (string path)
 		{
 			try {
 				if (!FileUtils.test (path, FileTest.IS_DIR))
 					return;
 					
	 			var dir = Dir.open (path);
	 			if (dir != null) {
	 				string file;
		 			while ((file = dir.read_name ()) != null) {
		 				if (file != null && file.has_suffix (".ini")) {
		 					string template_name = Path.get_basename (file).substring (0, file.length - 4);
		 					string tar_filename = Path.build_filename (path, template_name + ".tar.gz"); 
		 					
		 					if (FileUtils.test (tar_filename, FileTest.IS_REGULAR | FileTest.IS_SYMLINK)) {
		 						var template_definition = TemplateDefinition.load (Path.build_filename (path, file));
		 						if (template_definition != null) {
		 							template_definition.id = _next_id;
			 						this._definitions.append (template_definition);
			 						_next_id++;
			 					}
		 					}
		 				}
		 			}
	 			}
	 		} catch (Error err) {
	 			critical ("error %s", err.message);
	 		}
 		}
 	}
 }
