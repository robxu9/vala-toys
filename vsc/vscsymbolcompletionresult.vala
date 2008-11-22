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
	public class SymbolCompletionResult
	{
		public Gee.List<SymbolCompletionItem> properties = new Gee.ArrayList<SymbolCompletionItem> ();
		public Gee.List<SymbolCompletionItem> classes = new Gee.ArrayList<SymbolCompletionItem> ();
		public Gee.List<SymbolCompletionItem> interfaces = new Gee.ArrayList<SymbolCompletionItem> ();
		public Gee.List<SymbolCompletionItem> structs = new Gee.ArrayList<SymbolCompletionItem> ();
		public Gee.List<SymbolCompletionItem> methods = new Gee.ArrayList<SymbolCompletionItem> ();
		public Gee.List<SymbolCompletionItem> fields = new Gee.ArrayList<SymbolCompletionItem> ();
		public Gee.List<SymbolCompletionItem> signals = new Gee.ArrayList<SymbolCompletionItem> ();
		public Gee.List<SymbolCompletionItem> others = new Gee.ArrayList<SymbolCompletionItem> ();
		public Gee.List<SymbolCompletionItem> namespaces = new Gee.ArrayList<SymbolCompletionItem> ();

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
				    + others.size;
			}
		}

		public bool classes_contains (string name) {
			return symbols_contains (classes, name);
		}

		public bool interfaces_contains (string name) {
			return symbols_contains (interfaces, name);
		}

		private bool symbols_contains (Gee.List<Vala.Symbol> data, string name)
		{
			if (data.size == 0)
				return false;

			foreach (Vala.Symbol item in data) {
				if (item is Symbol && item.name == name) {
					return true;
				}
			}

			return false;
		}
	}
}
