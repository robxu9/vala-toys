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
		public string return_type_name = null;

		public Gee.List<SymbolCompletionItem> parameters = null;

		public SymbolCompletionItem (string name) 
		{
			this.name = name;
		}

		public SymbolCompletionItem.with_method (Method method)
		{
			this.name = method.name;
			this.parameters = new Gee.ArrayList<SymbolCompletion> ();
		}
	}
}