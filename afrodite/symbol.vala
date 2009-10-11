/* symbol.vala
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
	[Flags]
	public enum SymbolAccessibility
	{
		PRIVATE = 1,
		INTERNAL = 1 << 1,
		PROTECTED = 1 << 2,
		PUBLIC = 1 << 3,
		ANY = SymbolAccessibility.PRIVATE | SymbolAccessibility.INTERNAL | SymbolAccessibility.PROTECTED | SymbolAccessibility.PUBLIC
	}

	[Flags]
	public enum MemberBinding {
		INSTANCE = 1,
		CLASS = 1 << 1,
		STATIC = 1 << 2,
		ANY = MemberBinding.INSTANCE | MemberBinding.CLASS | MemberBinding.STATIC
	}

	public class Symbol : Object
	{
		public static VoidType VOID = new VoidType ();
		
		public string name = null;
		public string fully_qualified_name = null;
		public unowned Symbol parent = null;
		public DataType return_type = null;
		public string type_name = null;
		public Gee.List<unowned Symbol> children = null;
		public Gee.List<SourceReference> source_references = null;
		public Gee.List<DataType> parameters = null;
		public Gee.List<DataType> local_variables = null;
		public Gee.List<DataType> base_types = null;
		public Gee.List<unowned Symbol> resolve_targets = null; // contains a reference to symbols of whose this symbol is a resolved reference for any target data type
		public SymbolAccessibility access = SymbolAccessibility.INTERNAL;
		public MemberBinding binding = MemberBinding.INSTANCE;
		public bool is_virtual = false;
		public bool is_abstract = false;
		public bool overrides = false;
		
		private Gee.List<Symbol> detached_children = null;
		private string _info = null;
		private string _des = null;
		private string _display_name = null;
		
		public Symbol (string? fully_qualified_name, string? type_name)
		{
			if (fully_qualified_name != null) {
				string[] parts = fully_qualified_name.split (".");
				name = parts[parts.length-1];
				this.fully_qualified_name = fully_qualified_name;
			}
			if (type_name != null)
				this.type_name = type_name.substring (4);
		}
		
		public void add_child (Symbol child)
		{
			if (children == null) {
				children = new ArrayList<Symbol> ();
			}
			
			children.add (child);
			child.parent = this;
		}
		
		public void remove_child (Symbol child)
		{
			children.remove (child);
			if (children.size == 0)
				children = null;
		}
		
		public Symbol? lookup_child (string name)
		{
			if (has_children) {
				foreach (Symbol s in children) {
					if (s.name == name) {
						return s;
					}
				}
			}			
			return null;
		}
		public bool has_children
		{
			get {
				return children != null;
			}
		}

		public void add_resolve_target (Symbol resolve_target)
		{
			if (resolve_targets == null) {
				resolve_targets = new ArrayList<Symbol> ();
			}
			
			resolve_targets.add (resolve_target);
		}
		
		public void remove_resolve_target (Symbol resolve_target)
		{
			resolve_targets.remove (resolve_target);
			if (resolve_targets.size == 0)
				resolve_targets = null;
		}
		
		public bool has_resolve_targets
		{
			get {
				return resolve_targets != null;
			}
		}

		public void add_parameter (DataType par)
		{
			if (parameters == null) {
				parameters = new ArrayList<DataType> ();
			}
			
			parameters.add (par);
		}
		
		public void remove_parameter (DataType par)
		{
			parameters.remove (par);
			if (parameters.size == 0)
				parameters = null;
		}

		public bool has_parameters
		{
			get {
				return parameters != null;
			}
		}
		
		public void add_local_variable (DataType variable)
		{
			if (local_variables == null) {
				local_variables = new ArrayList<DataType> ();
			}
			
			local_variables.add (variable);
		}
		
		public void remove_local_variable (DataType variable)
		{
			local_variables.remove (variable);
			if (local_variables.size == 0)
				local_variables = null;
		}

		public bool has_local_variables
		{
			get {
				return local_variables != null;
			}
		}

		public void add_base_type (DataType type)
		{
			if (base_types == null) {
				base_types = new ArrayList<DataType> ();
			}
			
			base_types.add (type);
		}
		
		public void remove_base_type (DataType type)
		{
			base_types.remove (type);
			if (base_types.size == 0)
				base_types = null;
		}

		public bool has_base_types
		{
			get {
				return base_types != null;
			}
		}
		
		public void add_source_reference (SourceReference reference)
		{
			if (source_references == null) {
				source_references = new ArrayList<SourceReference> ();				
			}
			source_references.add (reference);
		}
		
		public void remove_source_reference (SourceReference reference)
		{
			source_references.remove (reference);
		}
		
		public SourceReference? lookup_source_reference_filename (string filename)
		{
			if (has_source_references) {
				foreach (SourceReference reference in source_references) {
					if (reference.file.filename == filename)
						return reference;
				}
			}
			
			return null;
		}
		
		public SourceReference? lookup_source_reference_sourcefile (SourceFile source)
		{
			if (has_source_references) {
				foreach (SourceReference reference in source_references) {
					if (reference.file == source)
						return reference;
				}
			}
			
			return null;
		}
		public bool has_source_references
		{
			get {
				return source_references != null;
			}
		}
		
		internal void add_detached_child (Symbol item)
		{
			if (!detached_children.contains (item))
				detached_children.add (item);
				
		}

		public Symbol detach_copy (int depth = 1, Symbol? root = null)
		{
			var res = new Symbol (fully_qualified_name, type_name);
			
			res.detached_children = new ArrayList<Symbol> ();
			

			// unowned copied symbols are references in the detached_children
			// collection of the root symbol. So no owned circular references
			// are made.
			if (root == null)
				root = res;

			debug ("copy %s in %s", fully_qualified_name, root.name);	
			res.parent = null; // parent reference isn't copied
			res.return_type = return_type == null ? null : return_type.copy (root);
			res.type_name = type_name;
			if (depth == -1 || (depth > 0 && has_children)) {
				foreach (Symbol child in children) {
					var copy = child.detach_copy (depth - 1, root);
					res.add_child (copy);
					root.add_detached_child (copy); 
				}
			}
			
			if (has_source_references) {
				foreach (SourceReference sr in source_references) {
					res.add_source_reference (sr.copy ());
				}
			}
			
			if (has_parameters) {
				foreach (DataType p in parameters) {
					res.add_parameter (p.copy (root));
				}
			}
			
			if (has_local_variables) {
				foreach (DataType l in local_variables) {
					res.add_local_variable (l.copy (root));
				}
			}
			
			if (has_base_types) {
				foreach  (DataType t in base_types) {
					res.add_base_type (t.copy (root));
				}
			}
			
			if (has_resolve_targets && (depth > 0 || depth == -1)) {
				foreach (Symbol t in resolve_targets) {
					var copy = t.detach_copy (0, root);
					res.add_resolve_target (copy);
					root.add_detached_child (copy);
				}
			}
			
			res._info = _info;
			res._des = _des;
			res.access = access;
			res.binding = binding;
			res.is_virtual = is_virtual;
			res.is_abstract = is_abstract;
			res.overrides = overrides;
			res._display_name = _display_name;
			return res;
		}
		
		public string description
		{
			get {
				if (_des == null)
					build_description ();
				
				return _des;
			}
		}
		
		public string info
		{
			get {
				if (_info == null)
					build_info ();
				
				return _info;
			}
		}
		
		public string display_name
		{
			get {
				if (_display_name == null) {
					return name;
				}
				
				return _display_name;
			}
			set {
				_display_name = value;
			}
		}

		private void build_info ()
		{
			int param_count = 0;
			string params;
			StringBuilder sb = new StringBuilder ();
			
			if (has_parameters) {
				foreach (DataType type in parameters) {
					sb.append_printf ("%s, ", type.description);
				}
				sb.truncate (sb.len - 2);
				params = sb.str; 
				sb.truncate (0);
			} else {
				params = "";
				param_count = 0;
			}
			
			sb.append_printf("%s: %s\n\n%s%s<b>%s</b> (%s%s)",
				    type_name,
				    display_name,
				    return_type != null ? return_type.description : "",
				    (param_count > 2 ? "\n" : " "),
				    display_name, 
				    (param_count > 2 ? "\n" : ""),
				    params);
				    
			if (!type_name.has_suffix ("Method")) {
				sb.truncate (sb.len - 3);
			}

			_info = sb.str;
		}
		
		private void build_description ()
		{
			var sb = new StringBuilder ();
			sb.append (this.access_string);
			sb.append (" ");
			if (binding_string != "") {
				sb.append (binding_string);
				sb.append (" ");
			}
			if (return_type != null) {
				sb.append_printf ("%s ", return_type.description);
			}
			sb.append (display_name);
			if (type_name.has_suffix ("Method")) {
				sb.append (" (");
			}
			if (has_parameters) {
				foreach (DataType type in parameters) {
					sb.append_printf ("%s, ", type.description);
				}
				sb.truncate (sb.len - 2);
			}
			if (type_name.has_suffix ("Method")) {
				sb.append (")");
			}
			
			if (has_base_types) {
				sb.append (" : ");
				foreach (DataType type in base_types) {
					sb.append_printf ("%s, ", type.description);
				}
				sb.truncate (sb.len - 2);
			}
			
			_des = sb.str;
		}
		
		public string access_string
		{
			owned get {
				string res;
				
				switch (access) {
					case Afrodite.SymbolAccessibility.PRIVATE:
						res = "private";
						break;
					case Afrodite.SymbolAccessibility.INTERNAL:
						res = "internal";
						break;
					case Afrodite.SymbolAccessibility.PROTECTED:
						res = "protected";
						break;
					case Afrodite.SymbolAccessibility.PUBLIC:
						res = "public";
						break;
					default:
						res = "unknown";
						break;
				}					
				return res;
			}
		}
		
		public string binding_string
		{
			owned get {
				string res;
				
				switch (binding) {
					case Afrodite.MemberBinding.CLASS:
						res = "class";
						break;
					case Afrodite.MemberBinding.INSTANCE:
						res = "";
						break;
					case Afrodite.MemberBinding.STATIC:
						res = "static";
						break;
					default:
						res = "unknown";
						break;
				}	
				return res;
			}
		}
	}
}
