/*
 *  vscsymbolcompletionitem.vala - Vala symbol completion library
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

namespace Vsc
{
	public class SymbolCompletionItem : GLib.Object
	{
		public string name;
		public string type_name = null;
		public string info;
		public string? file;
		public int first_line = 0;
		public int last_line = 0;
		public Symbol? symbol;
		
		public SymbolCompletionItem (string name)
		{
			this.name = name;
			this.info = name;
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

		private string formal_parameters_to_string (Gee.List<FormalParameter> parameters)
		{
			string params = "";
			string param_sep = " ";
			if (parameters.size > 2) {
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
					if (parameter.default_expression != null) {
						default_expr = " = " + parameter.default_expression.to_string ();
					}
					if (parameter.parameter_type != null) {
						parameter_type = data_type_to_string (parameter.parameter_type);
					} else {
						parameter_type = "unknown";
					}
					params = "%s,%s%s%s %s%s".printf (params, param_sep, direction, parameter_type, parameter.name, default_expr);
				}
			}
			if (params != "") {
				params = params.substring (2, params.length - 2);
			}
			params = Markup.escape_text (params);
			return params;
		}

		public SymbolCompletionItem.with_method (Method item)
		{
			this.name = item.name;
			this.file = item.source_reference.file.filename;
			this.first_line = item.source_reference.first_line;
			this.last_line = (0 == item.body.source_reference.last_line)? first_line: item.body.source_reference.last_line;
			this.symbol = item;
			
			if (name.has_prefix ("new")) {
				name = name.substring (3, name.length - 3);
				if (name == "") {
					name = item.parent_symbol.name;
				} else if (name.has_prefix (".")) {
					name = name.substring (1, name.length - 1);
				}
			}

			int param_count = item.get_parameters ().size;
			var params = formal_parameters_to_string (item.get_parameters ());

			this.info = "Method: %s\n\n%s%s<b>%s</b> (%s%s)".printf (
			    name,
			    data_type_to_string (item.return_type),
			    (param_count > 2 ? "\n" : " "),
			    name, 
			    (param_count > 2 ? "\n" : ""),
			    params);
		}

		public SymbolCompletionItem.with_creation_method (CreationMethod item)
		{
			this.name = ("new" == item.name)? 
			            item.parent_symbol.name: 
			            "%s.%s".printf (item.parent_symbol.name, item.name);
			this.file = item.source_reference.file.filename;
			this.first_line = item.source_reference.first_line;
			this.last_line = (0 == item.body.source_reference.last_line)? first_line: item.body.source_reference.last_line;
			this.symbol = item;
			
			int param_count = item.get_parameters ().size;
			var params = formal_parameters_to_string (item.get_parameters ());

			this.info = "CreationMethod: %s\n\n%s%s<b>%s</b> (%s%s)".printf (
			    name,
			    data_type_to_string (item.return_type),
			    (param_count > 2 ? "\n" : " "),
			    name, 
			    (param_count > 2 ? "\n" : ""),
			    params);
		}

		public SymbolCompletionItem.with_field (Field item)
		{
			this.name = item.name;
			this.file = item.source_reference.file.filename;
			this.first_line = item.source_reference.first_line;
			this.last_line = item.source_reference.last_line;
			this.symbol = item;
			
			string default_expr = "";
			if (item.initializer != null) {
				default_expr = " = " + item.initializer.to_string ();
			}
			this.info = "Field: %s\n\n%s <b>%s</b>%s".printf (
			    name,
			    data_type_to_string (item.field_type),
			    name, 
			    default_expr);
		}

		public SymbolCompletionItem.with_property (Property item)
		{
			this.name = item.name;
			this.file = item.source_reference.file.filename;
			this.first_line = item.source_reference.first_line;
			this.last_line = item.source_reference.first_line;
			this.symbol = item;
			
			// Choose later of accessors' last lines
			if (null != item.get_accessor) {
				this.last_line = item.get_accessor.body.source_reference.last_line;
				if (null != item.set_accessor && item.set_accessor.body.source_reference.last_line > this.last_line) {
					this.last_line = item.set_accessor.body.source_reference.last_line;
				}
			}
			
			string default_expr = "";
			if (item.default_expression != null) {
				default_expr = " = " + item.default_expression.to_string ();
			}
			this.info = "Property: %s\n\n%s <b>%s</b>%s".printf (
			    name,
			    data_type_to_string (item.property_type),
			    name, 
			    default_expr);
		}

		public SymbolCompletionItem.with_struct (Struct item)
		{
			this.name = item.name;
			this.info = "Struct: %s".printf (item.name);
			this.file = item.source_reference.file.filename;
			this.first_line = item.source_reference.first_line;
			this.last_line = item.source_reference.last_line;
			this.symbol = item;
		}

 		public SymbolCompletionItem.with_class (Class item)
		{
			this.name = item.name;
			this.info = "Class: %s".printf (item.name);
			this.file = item.source_reference.file.filename;
			this.first_line = item.source_reference.first_line;
			this.last_line = item.source_reference.last_line;
			this.symbol = item;
		}

 		public SymbolCompletionItem.with_interface (Interface item)
		{
			this.name = item.name;
			this.info = "Interface: %s".printf (item.name);
			this.file = item.source_reference.file.filename;
			this.first_line = item.source_reference.first_line;
			this.last_line = item.source_reference.last_line;
			this.symbol = item;
		}

 		public SymbolCompletionItem.with_signal (Vala.Signal item)
		{
			this.name = item.name;
			this.info = "Signal: %s".printf (item.name);
			this.file = item.source_reference.file.filename;
			this.first_line = item.source_reference.first_line;
			this.last_line = item.source_reference.last_line;
			this.symbol = item;
			int param_count = item.get_parameters ().size;
			var params = formal_parameters_to_string (item.get_parameters ());

			this.info = "Signal: %s\n\n%s%s<b>%s</b> (%s%s)".printf (
			    name,
			    data_type_to_string (item.return_type),
			    (param_count > 2 ? "\n" : " "),
			    name, 
			    (param_count > 2 ? "\n" : ""),
			    params);
		}

		public SymbolCompletionItem.with_namespace (Namespace item)
		{
			this.name = item.name;
			this.info = "Namespace: %s".printf (item.name);
			this.file = item.source_reference.file.filename;
			this.first_line = item.source_reference.first_line;
			this.last_line = item.source_reference.last_line;
			this.symbol = item;
		}
	}
}
