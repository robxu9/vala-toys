/* datatype.vala
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
using Gee;

namespace Afrodite
{
	public class DataType
	{
		private string _type_name = null;
		
		public string name = null;
		
		public unowned Symbol? symbol = null;
		public bool is_array = false;
		public bool is_pointer = false;
		public bool is_generic = false;
		public bool is_nullable = false;
		public string default_expression = null;
		
		public DataType (string type_name, string? name = null)
		{
			this.name = name;
			this.type_name = type_name;
		}

		public string type_name
		{
			get {
				return _type_name;
			}
			set {
				_type_name = process_type_name (fix_simple_type_name (value));
			}
		}

		public bool unresolved
		{
			get {
				return type_name != null && symbol == null;
			}
		}

		private string fix_simple_type_name (string type_name)
		{
			// HACK: this should fix bogus binary inferred type eg. int.float.double.int etc
			string[] types = type_name.split (".");
			
			if (types.length > 1) {
				string result = null;
				foreach (string type in types) {
					if (type != "int" && type != "float" && type != "double") {
						// type not known giving up
						return type_name;
					}
				
					if (result == null) {
						result = type;
					} else if (result != type) {
						if (result == "int" && (type == "float" || type == "double")) {
							result = type;
						}
					}
				}
				return result;
			} else {
				return type_name;
			}
			
		}
		
		private string process_type_name (string type_name)
		{
			var sb = new StringBuilder ();
			int skip_level = 0; // skip_level == 0 --> add char, skip_level > 0 --> skip until closed par (,[,<,{ causes a skip until ),],>,}
			
			for (int i = 0; i < type_name.length; i++) {
				unichar ch = type_name[i];
				
				if (skip_level > 0) {
					if (ch == ']' || ch == '>')
						skip_level--;
					
					continue;
				}
				
				if (ch == '*') {
					is_pointer = true;
				} else if (ch == '?') {
					is_nullable = true;
				} else if (ch == '!') {
					is_nullable = false; // very old vala syntax!!!
				} else if (ch == '[') {
					is_array = true;
					skip_level++;
				} else if (ch == '<') {
					is_generic = true;
					skip_level++;
				} else
					sb.append_unichar (ch);
			}
			return sb.str;
		}
		
		public DataType copy (Symbol? root = null)
		{
			var res = new DataType (type_name, name);
			
			res.symbol = symbol;
			if (root != null && res.symbol != null) {
				root.add_detached_child (symbol);
			}
			res.is_array = is_array;
			res.is_pointer = is_pointer;
			res.is_generic = is_generic;
			res.is_nullable = is_nullable;
			res.default_expression = default_expression;
			
			return res;
		}
		
		public string description		
		{
			owned get {
				string res = type_name;
				
				if (name == null || name == "") {
					res += " <?>";
				} else {
					res += " %s".printf (name);
				}
				
				return res;
			}
		}
	}
}
