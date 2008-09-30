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
	public class SymbolCompletionItem
	{
		public string name;
		public string type_name = null;
		public string info;

		public SymbolCompletionItem (string name) 
		{
			this.name = name;
			this.info = name;
		}

		public SymbolCompletionItem.with_method (Method method)
		{
			this.name = method.name;
			
			string params = "";
			int param_count = 0;
			string param_sep = " ";
			if (method.get_parameters ().size > 2) {
				param_sep = "\n\t\t";
			}

			foreach (FormalParameter parameter in method.get_parameters ()) {
				string direction = "";
				string default_expr = "";
				string parameter_type = "";
				param_count++;
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
						parameter_type = parameter.parameter_type.data_type.name;
						if (parameter.parameter_type.is_array ()) {
							parameter_type += "[]";
						}
						if (parameter.parameter_type.nullable ) {
							parameter_type += "?";
						}
						if (parameter.parameter_type.is_dynamic) {
							parameter_type = "dynamic " + parameter_type;
						}
					} else {
						parameter_type = "<unkown>";
					}
					params = "%s,%s%s%s %s%s".printf (params, param_sep, direction, parameter_type, parameter.name, default_expr);
				}
			}
			if (params != "") {
				params = params.substring (2, params.length - 2);
			}
			this.info = "%s%s<b>%s</b> (%s%s)".printf (
				method.return_type.to_string (), 
				(param_count > 2 ? "\n" : " "),
				name, 
				(param_count > 2 ? "\n" : ""),
				params);
		}
	}
}