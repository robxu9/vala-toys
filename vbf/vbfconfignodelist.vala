/*
 *  vbfconfignodelist.vala - Vala Build Framework library
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
using Gee;

namespace Vbf
{
	public class ConfigNodeList : ConfigNode
	{
		protected Gee.List<ConfigNode> values = new ArrayList<ConfigNode> ();
		
		public Gee.List<ConfigNode> get_values ()
		{
			return new ReadOnlyList<ConfigNode> (values);
		}

		public void add_value (ConfigNode val)
		{
			values.add (val);
		}
		
		public void replace_config_node (ConfigNode source, ConfigNode target)
		{
			if (values.contains (source)) {
				values.remove (source);
				if (target != null)
					values.add (target);
			}
		}
		
		public override string to_string ()
		{
			string res = "";
			foreach (ConfigNode item in values) {
				if (item != null)
					res += "%s, ".printf (item.to_string ());
				else
					critical ("item is null");
			}
			if (res.length > 2)
				res = res.substring (0, res.length - 2);
			
			return res;
		}
	}
}
