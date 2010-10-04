/*
 *  vbfpackage.vala - Vala Build Framework library
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

namespace Vbf
{
	public class Package : GLib.Object
	{
		public string id;
		public string name;
		public string constraint;
		public ConfigNode version;
		public unowned Target parent_target = null;
		public unowned Group parent_group = null;
		public unowned Module parent_module = null;
		
		private string _uri;
		
		public Package (string id)
		{
			this.id = id;
			this.name = id;
		}
		
		public string uri
		{
			get {
				if (_uri == null) {
					initialize_uri ();
				}
				
				return _uri;
			}
		}
		
		private void initialize_uri ()
		{
			var ctx = new Vala.CodeContext();
			string[] vapi_dirs = null;
			
			if (parent_target != null) {
				vapi_dirs = new string[parent_target.get_include_dirs ().size];
				int i = 0;
				foreach (string vapi_dir in parent_target.get_include_dirs ()) {
					vapi_dirs[i] = vapi_dir + "/";
					Utils.trace ("**** adding vapidir: %s", vapi_dir);
					i++;
				}
			}
			
			try {
				ctx.vapi_directories = vapi_dirs;
				string package_filename = ctx.get_vapi_path (id);
				if (package_filename == null) {
					critical ("no vapi file for package: %s", id);
				} else {
					_uri = GLib.Filename.to_uri (package_filename);
				}
			} catch (Error err) {
				critical ("error getting the uri for %s: %s", id, err.message);
			}
		}
	}
}

