/*
 *  vscsymbolcompletionresult.vala - Vala symbol completion library
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
	public class SymbolCompletionResult : GLib.Object
	{
		public Vala.List<SymbolCompletionItem> properties = new Vala.ArrayList<SymbolCompletionItem> ();
		public Vala.List<SymbolCompletionItem> classes = new Vala.ArrayList<SymbolCompletionItem> ();
		public Vala.List<SymbolCompletionItem> interfaces = new Vala.ArrayList<SymbolCompletionItem> ();
		public Vala.List<SymbolCompletionItem> structs = new Vala.ArrayList<SymbolCompletionItem> ();
		public Vala.List<SymbolCompletionItem> methods = new Vala.ArrayList<SymbolCompletionItem> ();
		public Vala.List<SymbolCompletionItem> fields = new Vala.ArrayList<SymbolCompletionItem> ();
		public Vala.List<SymbolCompletionItem> signals = new Vala.ArrayList<SymbolCompletionItem> ();
		public Vala.List<SymbolCompletionItem> others = new Vala.ArrayList<SymbolCompletionItem> ();
		public Vala.List<SymbolCompletionItem> namespaces = new Vala.ArrayList<SymbolCompletionItem> ();
		public Vala.List<SymbolCompletionItem> enums = new Vala.ArrayList<SymbolCompletionItem> ();
		public Vala.List<SymbolCompletionItem> constants = new Vala.ArrayList<SymbolCompletionItem> ();
		public Vala.List<SymbolCompletionItem> error_domains = new Vala.ArrayList<SymbolCompletionItem> ();
		
		public bool is_empty
		{
			get {
				return this.count == 0;
			}
		}

		public int count
		{
			get {
				return properties.size
				    + classes.size 
				    + interfaces.size
				    + structs.size
				    + methods.size
				    + fields.size
				    + signals.size
				    + namespaces.size
				    + enums.size
				    + error_domains.size
				    + constants.size
				    + others.size;
			}
		}

		public bool namespaces_contain (string name) {
			return symbols_contain (namespaces, name);
		}
		
		public bool classes_contain (string name) {
			return symbols_contain (classes, name);
		}

		public bool interfaces_contain (string name) {
			return symbols_contain (interfaces, name);
		}

		public bool structs_contain (string name) {
			return symbols_contain (structs, name);
		}

		public bool constants_contain (string name) {
			return symbols_contain (constants, name);
		}
		
		public bool enums_contain (string name) {
			return symbols_contain (enums, name);
		}

		public bool methods_contain (string name) {
			return symbols_contain (methods, name);
		}

		public bool delegates_contain (string name) {
			return symbols_contain (others, name);
		}

		public bool signals_contain (string name) {
			return symbols_contain (signals, name);
		}

		public bool fields_contain (string name) {
			return symbols_contain (fields, name);
		}

		public bool properties_contain (string name) {
			return symbols_contain (properties, name);
		}

		public bool error_domains_contain (string name) {
			return symbols_contain (error_domains, name);
		}
		
		private bool symbols_contain (Vala.List<SymbolCompletionItem> data, string name)
		{
			if (data.size == 0)
				return false;
				
			foreach (SymbolCompletionItem item in data) {
				if (item.name == name) {
					return true;
				}
			}

			return false;
		}
	}
}
