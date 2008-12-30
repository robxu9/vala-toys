/*
 *  vscsymbolcompletionfilteroptions.vala - Vala symbol completion library
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

namespace Vsc
{
	public class SymbolCompletionFilterOptions
	{
		public bool static_symbols;
		public bool interface_symbols;
		public bool constructors;
		public bool instance_symbols;
		
		public bool imported_namespaces;		
		public bool local_variables;
		public bool error_domains;
		public bool error_base;
				
		public bool private_symbols;
		public bool public_symbols;
		public bool protected_symbols;
		public bool internal_symbols;

		public string exclude_type;

		public SymbolCompletionFilterOptions ()
		{
			defaults ();
		}
		
		public void defaults ()
		{
			static_symbols = true;
			interface_symbols = true;
			instance_symbols = true;
			constructors = false;
			imported_namespaces = false;
			local_variables = false;
			error_domains = false;
			error_base = false;			
			private_symbols = true;
			public_symbols = true;
			protected_symbols = true;
			internal_symbols = true;
			exclude_type = null;
		}
		
		public void public_only ()
		{
			public_symbols = true;
			private_symbols = false;
			protected_symbols = false;
			internal_symbols = false;
		}
	}
}
