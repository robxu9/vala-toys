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
using Vala;

namespace Afrodite
{	
	public class Symbol : Object
	{
		public static VoidType VOID = new VoidType ();
		public static EllipsisType ELLIPSIS = new EllipsisType ();
		
		public unowned Symbol parent = null;
		public Vala.List<unowned Symbol> children = null;
		public Vala.List<unowned Symbol> resolve_targets = null; // contains a reference to symbols of whose this symbol is a resolved reference for any target data type
		
		public string name = null;
		public string fully_qualified_name = null;
		
		public DataType return_type = null;
		public string type_name = null;
		
		public Vala.List<SourceReference> source_references = null;
		public Vala.List<DataType> parameters = null;
		public Vala.List<DataType> local_variables = null;
		public Vala.List<DataType> base_types = null;
		public Vala.List<Symbol> generic_type_arguments = null;
		
		public SymbolAccessibility access = SymbolAccessibility.INTERNAL;
		public MemberBinding binding = MemberBinding.INSTANCE;
		public bool is_virtual = false;
		public bool is_abstract = false;
		public bool overrides = false;
		internal int _static_child_count = 0;
		internal int _creation_method_child_count = 0;

		private Vala.List<Symbol> detached_children = null;
		private string _info = null;
		private string _des = null;
		private string _markup_des = null;
		private string _display_name = null;
		
		public Symbol (string? fully_qualified_name, string? type_name)
		{
			if (fully_qualified_name != null) {
				string[] parts = fully_qualified_name.split (".");
				name = parts[parts.length-1];
				this.fully_qualified_name = fully_qualified_name;
			}
			if (type_name != null && type_name.has_prefix ("Vala"))
				this.type_name = type_name.substring (4);
		}
		
		public int static_child_count
		{
			get {
				return _static_child_count;
			}
			set {
				var delta = _static_child_count - value;
				_static_child_count = value;
				if (parent != null)
					parent.static_child_count += delta;
			}
		}

		public int creation_method_child_count
		{
			get {
				return _creation_method_child_count;
			}
			set {
				var delta = _creation_method_child_count - value;
				_creation_method_child_count = value;
				if (parent != null)
					parent.creation_method_child_count += delta;
			}
		}

		public void add_child (Symbol child)
		{
			if (children == null) {
				children = new ArrayList<Symbol> ();
			}
			
			children.add (child);
			child.parent = this;
			if (child.is_static || child.has_static_child) {
				static_child_count++;
			}
			if (child.type_name == "CreationMethod" || child.has_creation_method_child) {
				creation_method_child_count++;
			}
		}
		
		public void remove_child (Symbol child)
		{
			children.remove (child);
			if (children.size == 0)
				children = null;
				
			if (_static_child_count > 0
				&& (child.is_static || child.has_static_child)) {
				static_child_count--;
			}
			if (_creation_method_child_count > 0 
				&& (child.type_name == "CreationMethod" || child.has_creation_method_child)) {
				creation_method_child_count++;
			}
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
			// resolve target collection can be accessed from multiple threads
			lock (resolve_targets) {
				if (resolve_targets == null) {
					resolve_targets = new ArrayList<Symbol> ();
				}
				resolve_targets.add (resolve_target);
			}
		}
		
		public void remove_resolve_target (Symbol resolve_target)
		{
			// resolve target collection can be accessed from multiple threads
			lock (resolve_targets) {
				resolve_targets.remove (resolve_target);
				if (resolve_targets.size == 0)
					resolve_targets = null;
			}
		}
		
		public bool has_resolve_targets
		{
			get {
				bool res;
				
				lock (resolve_targets) {
					res = resolve_targets != null;
				}
				
				return res;
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
		
		public void add_generic_type_argument (Symbol sym)
		{
			if (generic_type_arguments == null) {
				generic_type_arguments = new ArrayList<Symbol> ();
			}
			
			//debug ("added generic %s to %s", sym.name, this.fully_qualified_name);
			generic_type_arguments.add (sym);
		}
		
		public void remove_generic_type_argument (Symbol sym)
		{
			generic_type_arguments.remove (sym);
			if (generic_type_arguments.size == 0)
				generic_type_arguments = null;
		}

		public bool has_generic_type_arguments
		{
			get {
				return generic_type_arguments != null;
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
			if (source_references.size == 0) {
				source_references = null;
			}
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

		public bool has_static_child
		{
			get {
				return _static_child_count > 0;
			}
		}

		public bool has_creation_method_child
		{
			get {
				return _creation_method_child_count > 0;
			}
		}
		
		public bool is_static			
		{
			get {
				return (binding & MemberBinding.STATIC) != 0;
			}
		}
		
		internal void add_detached_child (Symbol item)
		{
			if (!detached_children.contains (item))
				detached_children.add (item);
				
		}

		internal Symbol? detached_children_find (string fully_qualified_name)
		{
			
			foreach (Symbol symbol in detached_children) {
				if (symbol.fully_qualified_name == fully_qualified_name) {
					return symbol;
				}
			}
			
			return null;
		}
/*
		private bool check_symbol (Symbol symbol, QueryOptions? options)
		{
			if ((symbol.access & options.access) != 0) {
				if (options.only_static_factories 
					&& ((!symbol.is_static && !symbol.has_static_child) || symbol.type_name == "Struct")) {
					return false;
				}
				if (options.only_creation_methods 
					&& symbol.type_name != "CreationMethod"
					&& symbol.type_name != "ErrorDomain"
					&& !symbol.has_creation_method_child) {
					return false;
				}
				if (options.exclude_creation_methods && symbol.type_name == "CreationMethod") {
					return false;
				}
				if (symbol.type_name == "Destructor") {
					return false;
				}

				return true;
			}
			
			return false;
		}

*/
		public bool check_options (QueryOptions? options)
		{
			if (options.exclude_code_node && (name == null || name.has_prefix ("!")))
				return false;

			if (options.all_symbols)
				return true;
			
			if ((access & options.access) != 0) {
				if (options.only_static_factories 
					&& ((!is_static && !has_static_child) || type_name == "Struct")) {
					return false;
				}
				if (options.only_creation_methods 
					&& type_name != "CreationMethod"
					&& type_name != "ErrorDomain"
					&& !has_creation_method_child) {
					return false;
				}
				if (options.exclude_creation_methods && type_name == "CreationMethod") {
					return false;
				}
				if (type_name == "Destructor") {
					return false;
				}

				return true;
			}
			
			return false;
		}
		
		public Symbol detach_full (QueryResult result, int depth = 1)
		{
			result.add_symbol (this);

			if (return_type != null)
				result.add_symbol (return_type.symbol);
				
			if (has_parameters) {
				foreach (DataType p in parameters) {
					result.add_symbol (p.symbol);
				}
			}
			
			if (has_local_variables) {
				foreach (DataType l in local_variables) {
					result.add_symbol (l.symbol);
				}
			}
			
			if (has_base_types) {
				foreach  (DataType t in base_types) {
					// the base types need to be treated at the same depth
					// of their parent for this reason 1 need to be added
					// to data_type_copy_depth variables
					if (t.symbol != null) {
						result.add_symbol (t.symbol.detach_full (result, depth + 1));
					}						
				}
			}
			
			return this;
		}
		
		public Symbol? detach_copy (int depth = 1, QueryOptions options, Symbol? root = null)
		{
			var res = new Symbol (fully_qualified_name, type_name);
			int data_type_copy_depth = 1;
			
			// unowned copied symbols are references in the detached_children
			// collection of the root symbol. So no owned circular references
			// are made.
			if (root == null)
				root = res;

			if (root.detached_children == null)
				root.detached_children = new ArrayList<Symbol> ();
			
			// try to avoid circular symbol copy
			if (fully_qualified_name != null) {
				Symbol detach_copy = root.detached_children_find (fully_qualified_name);
				if (detach_copy != null) {
					debug ("Symbol already copied %s", fully_qualified_name);
					return detach_copy; // the symbol was already copied
				}
			}
			
			if (res != root)
				root.add_detached_child (res);
			//debug ("copy %s in %s", fully_qualified_name, root.name);	
			res.parent = null; // parent reference isn't copied
			res.fully_qualified_name = fully_qualified_name;
			res.type_name = type_name;
			res._static_child_count = _static_child_count;
			res._creation_method_child_count = _creation_method_child_count;
			res._info = _info;
			res._des = _des;
			res._markup_des = _markup_des;
			res.access = access;
			res.binding = binding;
			res.is_virtual = is_virtual;
			res.is_abstract = is_abstract;
			res.overrides = overrides;
			res._display_name = _display_name;
			
			if ((depth == -1 || depth > 0) && has_children) {
				foreach (Symbol child in children) {
					if (child.check_options (options)) {
						var copy = child.detach_copy (depth - 1, options, root);
						res.add_child (copy);
						 // a check is performed on the add to avoid duplicate copies
					}
				}
				
			}
			
			res.return_type = return_type == null ? null : return_type.copy (1, options, root);
			
			if (has_source_references) {
				foreach (SourceReference sr in source_references) {
					res.add_source_reference (sr.copy ());
				}
			}
			
			if (has_parameters) {
				foreach (DataType p in parameters) {
					res.add_parameter (p.copy (data_type_copy_depth, options, root));
				}
			}
			
			if (has_generic_type_arguments) {
				foreach (Symbol s in generic_type_arguments) {
					res.add_generic_type_argument (s);
				}
			}
			
			if (has_local_variables) {
				foreach (DataType l in local_variables) {
					res.add_local_variable (l.copy (data_type_copy_depth, options, root));
				}
			}
			
			if (has_base_types) {
				foreach  (DataType t in base_types) {
					// the base types need to be treated at the same depth
					// of their parent for this reason 1 need to be added
					// to data_type_copy_depth variables
					res.add_base_type (t.copy (data_type_copy_depth == -1 ? data_type_copy_depth : data_type_copy_depth + 1, options, root));
				}
			}

			return res;
		}
		
		public string description
		{
			get {
				if (_des == null)
					_des = build_description (false);
				
				return _des;
			}
		}

		public string markup_description
		{
			get {
				if (_markup_des == null)
					_markup_des = build_description (true);
				
				return _markup_des;
			}
		}

		public string info
		{
			get {
				if (_info == null)
					_info = build_info ();
				
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

		private string build_info ()
		{
			int param_count = 0;
			string params;
			string generic_args;
			
			StringBuilder sb = new StringBuilder ();

			if (has_generic_type_arguments) {
				sb.append ("&lt;");
				foreach (Symbol s in generic_type_arguments) {
					sb.append_printf ("%s, ", s.name);
				}
				sb.truncate (sb.len - 2);
				sb.append ("&gt;");
				generic_args = sb.str;
				sb.truncate (0);
				
			} else {
				generic_args = "";
			}
			
			if (has_parameters) {
				param_count = parameters.size;
				
				string sep;
				if (param_count > 2) {
					sep = "\n";
				} else {
					sep = " ";
				}
				
				foreach (DataType type in parameters) {
					sb.append_printf ("%s,%s", type.description, sep);
				}
				sb.truncate (sb.len - 2);
				params = sb.str; 
				sb.truncate (0);
			} else {
				params = "";
			}
			
			sb.append_printf("%s: %s\n\n%s%s<b>%s</b> %s (%s%s)",
				    type_name,
				    display_name,
				    return_type != null ? return_type.description : "",
				    (param_count > 2 ? "\n" : " "),
				    display_name, generic_args,
				    (param_count > 2 ? "\n" : ""),
				    params);
				    
			if (type_name != null && !type_name.has_suffix ("Method")) {
				sb.truncate (sb.len - 3);
			}

			return sb.str;
		}
		
		private string build_description (bool markup)
		{
			var sb = new StringBuilder ();
			if (type_name != "EnumValue") {
				sb.append (this.access_string);
				sb.append (" ");
				if (binding_string != "") {
					sb.append (binding_string);
					sb.append (" ");
				}
			}
			
			if (return_type != null) {
				if (type_name == "Constructor") {
					sb.append ("constructor: ");
				} else
					sb.append_printf ("%s ", return_type.description);
			}
			if (markup 
			    && type_name != null
			    && (type_name == "Property" 
			    || type_name.has_suffix ("Method")
			    || type_name.has_suffix ("Signal")
			    || type_name == "Field"
			    || type_name == "Constructor"))
				sb.append_printf ("<b>%s</b>".printf(display_name));
			else
				sb.append (display_name);

			if (has_generic_type_arguments) {
				sb.append ("&lt;");
				foreach (Symbol s in generic_type_arguments) {
					sb.append_printf ("%s, ", s.name);
				}
				sb.truncate (sb.len - 2);
				sb.append ("&gt;");
			}
			
			if (type_name != null 
				&& (has_parameters || type_name.has_suffix ("Method") || type_name.has_suffix("Signal"))) {
				sb.append (" (");
			}
			if (has_parameters) {
				foreach (DataType type in parameters) {
					sb.append_printf ("%s, ", type.description);
				}
				sb.truncate (sb.len - 2);
			}
			if (type_name != null
				&& (has_parameters || type_name.has_suffix ("Method") || type_name.has_suffix("Signal"))) {
				sb.append (")");
			}
			
			if (has_base_types) {
				sb.append (" : ");
				foreach (DataType type in base_types) {
					sb.append_printf ("%s, ", type.description);
				}
				sb.truncate (sb.len - 2);
			}
			
			return sb.str;
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
