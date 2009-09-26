/*
 *  vscsymbol.vala - Vala symbol completion library
 *  
 *  Copyright (C) 2009 - Andrea Del Signore <sejerpz@tin.it>
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

namespace Vsc
{
	public class SymbolItem : GLib.Object
	{
		public weak SymbolItem? parent = null;
		public Symbol? symbol = null;
		
		private Gee.ArrayList<SymbolItem> _children = null;
		private string _name = null;
		private string _description = null;
		
		public string name
		{
			get {
				return _name;
			}
		}
		
		public string description {
			get {
				return _description;
			}
		}
		
		public Gee.ArrayList<SymbolItem> children 
		{
			get {
				return _children;
			}
		}
		
		public SymbolItem (Symbol symbol, SymbolItem? parent = null)
		{
			this.symbol = symbol;
			this.parent = parent;
			
			// generate the name
			_name = symbol.name;
			if (symbol is CreationMethod) {
				if (symbol.parent_symbol != null) {
					_name = symbol.parent_symbol.name;
					if (symbol.name != ".new")
						_name = _name.concat (".", symbol.name);
				}
			}
			
			// generate the description
			if (symbol is Vala.Method || symbol is Vala.CreationMethod) {
				var method = (Vala.Method) symbol;
				_description = "%s (%s)".printf (name, parameters_to_string (method.get_parameters(), true));
			} else {
				_description = name;
			}			
		}

		public void add_child (SymbolItem child)
		{
			if (_children == null) {
				_children = new Gee.ArrayList<SymbolItem> ();
			}
			
			_children.add (child);
			child.parent = this;
		}

		private string parameters_to_string (Gee.List<FormalParameter> parameters, bool compact = false)
		{
			string params = "";
			string param_sep = " ";
			if (!compact && parameters.size > 2) {
				param_sep = "\n\t\t";
			}

			foreach (FormalParameter parameter in parameters) {
				string direction = "";
				string default_expr = "";
				string parameter_type = "";

				if (parameter.ellipsis) {
					params = "%s, %s".printf (params, "...");
				} else {
					if (parameter.direction == ParameterDirection.OUT) {
						direction = "out ";
					} else if (parameter.direction == ParameterDirection.REF) {
						direction = "ref ";
					}
					if (parameter.default_expression != null && parameter.default_expression.symbol_reference != null) {
						default_expr = " = " + parameter.default_expression.to_string ();
					}
					if (parameter.parameter_type != null) {
						parameter_type = data_type_to_string (parameter.parameter_type);
					} else {
						parameter_type = "unknown";
					}
					params = params.concat (",", param_sep, direction, parameter_type);
					if (!compact)
						params = params.concat (" ", parameter.name);
						
					params = params.concat (default_expr);
				}
			}
			if (params != "") {
				params = params.substring (2, params.length - 2);
			}
			params = Markup.escape_text (params);
			return params;
		}
		
		private string data_type_to_string (DataType type)
		{
			string result;

			result = type.to_qualified_string ();
			if (result == null) {
				result = "void";
			}

			var type_args = type.get_type_arguments ();
			if (type_args.size > 0 && result.str ("<") == null) {
				result += "<";
				bool first = true;
				foreach (DataType type_arg in type_args) {
					if (!first) {
						result += ",";
					} else {
						first = false;
					}
					if (!type_arg.value_owned) {
						result += "weak ";
					}
					result += data_type_to_string (type_arg);
				}
				result += ">";
			}

			if (type.nullable && !result.has_suffix ("?") && !result.has_suffix("*")) {
				result += "?";
			}
			if (type.is_dynamic) {
				result = "dynamic " + result;
			}

			result = Markup.escape_text (result);
			return result;
		}
	}
}

