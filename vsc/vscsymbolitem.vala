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
		
		public string name {
			get {
				return symbol.name;
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
		}

		public void add_child (SymbolItem child)
		{
			if (_children == null) {
				_children = new Gee.ArrayList<SymbolItem> ();
			}
			
			_children.add (child);
			child.parent = this;
		}
	}
}

