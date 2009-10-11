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
		public unowned SymbolItem? parent = null;
		
		private Gee.ArrayList<SymbolItem> _children = null;
		private string _name = null;
		private string _description = null;
		private string _info = null;
		private string _file = null;
		private int _first_line = 0;
		private int _last_line = 0; // this variabile can contain the last line of the symbol body
		private int _first_column = 0;
		private int _last_column = 0;
		private string _type_name = null;
		private SymbolAccessibility _access;
		private string _serialize_info = null;
		
		public string name
		{
			get {
				return _name;
			}
		}
		
		public string description 
		{
			get {
				return _description;
			}
		}
		
		public string info
		{
			get {
				return _info;
			}
		}
		
		public string? file
		{
			get {
				return _file;
			}
		}
		
		public int first_line
		{
			get {
				return _first_line;
			}
		}
		
		public int last_line
		{
			get {
				return _last_line;
			}
		}

		public int first_column
		{
			get {
				return _first_column;
			}
		}

		public int last_column
		{
			get {
				return _last_column;
			}
		}

		public string type_name
		{
			get {
				return _type_name;
			}
		}

		public string serialize_info
		{
			get {
				return _serialize_info;
			}
		}

		public SymbolAccessibility access
		{
			get {
				return _access;
			}
		}

		public Gee.ArrayList<SymbolItem> children 
		{
			get {
				return _children;
			}
		}
		
		public SymbolItem (Symbol symbol, SymbolItem? parent = null, bool create_serialize_info = false)
		{
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

			if (symbol.source_reference != null) {
				_first_line = symbol.source_reference.first_line;
				_file = symbol.source_reference.file.filename;
				_first_column = symbol.source_reference.first_column;
				_last_column = symbol.source_reference.last_column;
			}

			_type_name = symbol.type_name;
			_access = symbol.access;

			initialize_info (symbol, create_serialize_info);
		}

		public void add_child (SymbolItem child)
		{
			if (_children == null) {
				_children = new Gee.ArrayList<SymbolItem> ();
			}

			_children.add (child);
			child.parent = this;
		}

		private string parameters_to_string (Gee.List<FormalParameter> parameters, bool compact = false, bool escape_text = true)
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
			
			if (escape_text) {
				params = Markup.escape_text (params);
			}
			return params;
		}
		
		private string data_type_to_string (DataType type, bool escape_text = true)
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
			
			if (escape_text) {
				result = Markup.escape_text (result);
			}
			return result;
		}
		
		private void initialize_info (Symbol symbol, bool create_serialize_info)
		{
			if (symbol is Method) {
				var item = (Method) symbol;
				if (item.body != null && item.body.source_reference != null) {
					_last_line = (item.body.source_reference.last_line == 0 ? first_line : item.body.source_reference.last_line);
				}
				_info = create_standard_info (symbol, item.return_type, item.get_parameters ());
				if (create_serialize_info)
					_serialize_info = serialize_method (item);
			} else if (symbol is Vala.Signal) {
				var item = (Vala.Signal) symbol;
				_info = create_standard_info (symbol, item.return_type, item.get_parameters ());
			} else if (symbol is Property) {
				var item = (Property) symbol;
				
				// Choose later of accessors' last lines
				if (item.get_accessor != null && item.get_accessor.body != null && item.get_accessor.body.source_reference != null) {
					_last_line = item.get_accessor.body.source_reference.last_line;
					if (item.set_accessor != null && item.set_accessor.body != null 
					    && item.set_accessor.body.source_reference != null
					    && item.set_accessor.body.source_reference.last_line > this.last_line) {
						_last_line = item.set_accessor.body.source_reference.last_line;
					}
				}
			
				string default_expr = "";
				if (item.default_expression != null && item.default_expression.symbol_reference != null) {
					default_expr = " = " + item.default_expression.to_string ();
				}
				_info = "Property: %s\n\n%s <b>%s</b>%s".printf (
				    name,
				    data_type_to_string (item.property_type, false),
				    name, 
				   default_expr);
			} else if (symbol is Field) {
				var item = (Field) symbol;
				
				string default_expr = "";
				if (item.initializer != null && item.initializer.symbol_reference != null) {
					default_expr = " = " + item.initializer.to_string ();
				}
				_info = "Field: %s\n\n%s <b>%s</b>%s".printf (
				    name,
				    data_type_to_string (item.field_type, false),
				    name, 
				    default_expr);
			} else {
				_info = "%s: %s".printf (symbol.type_name.replace ("Vala", ""), name);
				if (symbol.source_reference != null)
					_last_line = symbol.source_reference.last_line;
			}
			
			if (create_serialize_info && !(symbol is Method))
				_serialize_info = serialize_symbol (symbol);	
		}
		
		private string create_standard_info (Symbol symbol, DataType return_type, Gee.List<FormalParameter>? parameters = null)
		{
			int param_count;
			string params;
			
			if (parameters != null) {
				params = parameters_to_string (parameters, false, false);
				param_count = parameters.size;
			} else {
				params = "";
				param_count = 0;
			}
			
			return "%s: %s\n\n%s%s<b>%s</b> (%s%s)".printf (
				    symbol.type_name.replace ("Vala", ""),
				    name,
				    data_type_to_string (return_type, false),
				    (param_count > 2 ? "\n" : " "),
				    name, 
				    (param_count > 2 ? "\n" : ""),
				    params);
		}

		/*
		 Support for vsc shell
		*/
		private string get_type_signature (Symbol symbol)
		{
				if (symbol is Vala.Enum) {
					return "enums";
				} else if (symbol is Vala.Constant) {
					return "constants";
				} else if (symbol is Vala.Namespace) {
					return "namespaces";
				} else if (symbol is Vala.Field) {
					return "field";
				} else if (symbol is Vala.Property) {
					return "property";
				} else if (symbol is Vala.Method) {
					return "method";
				} else if (symbol is Vala.Signal) {
					return "signal";
				} else if (symbol is Vala.Class) {
					return "class";
				} else if (symbol is Vala.Interface) {
					return "interface";
				} else if (symbol is Vala.Struct) {
					return "struct";
				} else {
					return "other";
				}
		}

		private string serialize_symbol (Symbol symbol)
		{
			string type = get_type_signature (symbol);
			return "%s:%s:%s;:;:;%s:%d;%d;\n".printf(type, symbol.name, get_access_string (symbol), _file, _first_line, _last_line);
		}

		private string serialize_method (Method method)
		{
			StringBuilder sb = new StringBuilder ();
			string typename;
			string is_owned;
			string symbol_type_signature = get_type_signature (method);

			if (method != null) {
				// TYPE:NAME:MODIFIER;STATIC:RETURN_TYPE;OWNERSHIP:ARGS;FILE:FIRST_LINE;LAST_LINE;
				var sometype = method.return_type;
				if (null != sometype) {
					typename = sometype.to_string();
					is_owned = sometype.value_owned ? "": "unowned";
				} else {
					is_owned = "";
					typename = "";
				}

				sb.append("%s:%s:%s;%s:%s;%s:".printf (symbol_type_signature, method.name, get_access_string (method), "", typename, is_owned));
				foreach (FormalParameter param in method.get_parameters ()) {
					//  name,vala type,OWNERSHIP
					sometype = param.parameter_type;
					if (sometype != null) {
						typename = sometype.to_string();
						is_owned = sometype.value_owned? "": "unowned";
					} else {
						is_owned = "";
						typename = "";
					}

					string paramname = ("(null)" == param.name.strip ())? "...": param.name;

					sb.append ("%s,%s,%s;".printf( paramname, typename, is_owned));
				}

				sb.append ("%s:%d;%d;\n".printf (_file, _first_line, _last_line));
			} else {
				sb.append ("%s:%s:;:;:;%s:%d;%d;\n".printf (symbol_type_signature, method.name, _file, _first_line, _last_line));
			}

			return sb.str;
		}

		private string get_access_string (Symbol symbol)
		{
			string access = "";

			switch (symbol.access) {
				case SymbolAccessibility.PUBLIC:
					access = "public";
					break;
				case SymbolAccessibility.PRIVATE:
					access = "private";
					break;
				case SymbolAccessibility.PROTECTED:
					access = "protected";
					break;
				case SymbolAccessibility.INTERNAL:
					access = "internal";
					break;
				default:
					break;
			}

 			return access;
		}

	}
}

