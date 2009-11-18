/*
 *  vbfvariable.vala - Vala Build Framework library
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
using Vala;

namespace Vbf
{
	public class Variable : ConfigNode
	{
		public string name;
		public ConfigNode? data = null;
		
		private Vala.List<unowned Variable> childs = new Vala.ArrayList<unowned Variable> ();
		
		public Variable (string name, ConfigNode parent)
		{
			this.name = name;
		}
		
		public Vala.List<Variable> get_childs ()
		{
			return new ReadOnlyList<Variable> (childs);
		}
		
		public void add_child (Variable variable)
		{
			childs.add (variable);
		}
		
		public override string to_string ()
		{
			string res;
			
			if (data is Variable) {
				res = "$(%s)=".printf (name);
			} else {
				res = "%s=".printf (name);
			}
			if (data == null) {
				res += "(null)";
			} else {
				res += data.to_string ();
			}
			return res;
		}
		
		public ConfigNode get_value ()
		{
			if (data is Variable) {
				return ((Variable) data).get_value ();
			} else {
				return data;
			}
		}
	}
}

