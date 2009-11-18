/*
 *  vbffile.vala - Vala Build Framework library
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
	public enum FileTypes
	{
		UNKNOWN,
		DATA,
		VALA_SOURCE,
		OTHER_SOURCE
	}
	
	public class File : GLib.Object
	{
		public string name;
		public string filename;	
		public string uri;
		public FileTypes type;
		public unowned Target target;
		
		public File (Target target, string filename)
		{
			this.with_type (target, filename, FileTypes.UNKNOWN);
		}
		
		public File.with_type (Target target, string filename, FileTypes type)
		{
			string file = filename;
			if (!Path.is_absolute (file)) {
				var f = GLib.File.new_for_path (file);
				file = f.resolve_relative_path (file).get_path ();
			}
			this.filename = file;
			try {
				this.uri = Filename.to_uri (file);	
			} catch (Error e) {
				GLib.warning ("error %s converting file %s to uri", e.message, file);
			}
			this.name = Filename.display_basename (file);
			this.target = target;
			this.type = type;
		}
	}
}

