/*
 *  vscsymbolcompletion.vala - Vala symbol completion library
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
	public errordomain SymbolCompletionError
	{
		PACKAGE_FILE_NOT_FOUND,
		PACKAGE_ALREADY_ADDED,
		UNSUPPORTED_SYMBOL_TYPE,
		UNSUPPORTED_TYPE,
		SOURCE_BUFFER
	}

	public class SymbolCompletion : GLib.Object
	{
		private List<string> _vapidirs = new List<string> ();
		private Gee.List<string> _packages = new Gee.ArrayList<string> ();
		private Gee.List<string> _sources = new Gee.ArrayList<string> ();
		private Gee.List<SourceBuffer> _source_buffers = new Gee.ArrayList<SourceBuffer> ();

		private CodeContext _pri_context;
		private CodeContext _sec_context;

		private string glib_file;

		private int need_parse_sec_context = 0;
		private int need_parse_pri_context = 0;

		private weak Thread parser_pri_thread = null;
		private weak Thread parser_sec_thread = null;

		public signal void cache_building ();
		public signal void cache_builded ();

		construct
		{
			_vapidirs.append ("/usr/share/vala/vapi");
			_vapidirs.append ("/usr/local/share/vala/vapi");
			try {
				var file = find_vala_package_name ("GLib");
				glib_file = find_vala_package_filename (file)[0];
			} catch (Error err) {
				error ("Can't find glib vapi file: %s", err.message);
			}
		}

		private void create_pri_thread ()
		{
			try {
				parser_pri_thread = Thread.create (this.parse_pri_contexts, false);
			} catch (ThreadError err) {
				error ("Can't create parser thread: %s", err.message);
			}
		}

		private void create_sec_thread ()
		{
			try {
				parser_sec_thread = Thread.create (this.parse_sec_contexts, false);
			} catch (ThreadError err) {
				error ("Can't create parser thread: %s", err.message);
			}
		}

		public bool add_package_from_namespace (string @namespace, bool auto_schedule_parse = true) throws Error
		{
			var package_name = find_vala_package_name (@namespace);
			return add_package (package_name, auto_schedule_parse);
		}

		public void remove_package_from_namespace (string @namespace) throws Error
		{
			var package_name = find_vala_package_name (@namespace);
			remove_package (package_name);
		}

		public void remove_package (string package_name) throws Error
		{
			Gee.List<string> files = find_vala_package_filename (package_name);
			if (list_contains_string (_packages, files[0])) {
				lock (_pri_context) {
					files.remove (files[0]);
				}
				schedule_parse ();
			}
		}

		public bool try_add_package (string package_name, bool auto_schedule_parse = true)
		{
			try {
				add_package (package_name, auto_schedule_parse);
				return true;
			} catch (Error err) {
				return false;
			}
		}

		public bool add_package (string package_name, bool auto_schedule_parse = true) throws Error
		{
			Gee.List<string> files = find_vala_package_filename (package_name);
			if (files.size > 0) {
				bool need_parse = false;

				lock (_pri_context) {
					foreach (string filename in files) {
						if (!list_contains_string (_packages, filename)) {
							_packages.add (filename);
							need_parse = true;
						}
					}
				}
				if (need_parse && auto_schedule_parse) {
					debug ("scheduling a parse");
					schedule_parse ();
				}
				return need_parse;
			} else {
				throw new SymbolCompletionError.PACKAGE_FILE_NOT_FOUND ("package file not found");
			}
		}

		public void add_source (string filename) throws Error
		{
			if (FileUtils.test (filename, FileTest.EXISTS)) {
				if (!list_contains_string (_sources, filename)) {
					lock (_pri_context) {
						_sources.add (filename);
					}
					schedule_parse ();
				}
			} else {
				throw new SymbolCompletionError.PACKAGE_FILE_NOT_FOUND ("source file not found");
			}
		}

		public void remove_source (string filename) throws Error
		{
			if (!list_contains_string (_sources, filename)) {
				lock (_pri_context) {
					_sources.remove (filename);
				}
				schedule_parse ();
			} else {
				throw new SymbolCompletionError.PACKAGE_FILE_NOT_FOUND ("source file not found");
			}
		}

		public bool contains_source (string filename)
		{
			return list_contains_string (_sources, filename);
		}

		public void add_source_buffer (SourceBuffer source) throws SymbolCompletionError
		{
			if (contains_source_buffer (source))
				throw new SymbolCompletionError.SOURCE_BUFFER ("source already added");

			debug ("added sourcebuffer: %s", source.name);
			lock (_sec_context) {
				_source_buffers.add (source);
			}
			schedule_parse_source_buffers ();
		}

		public void remove_source_buffer_by_name (string name) throws SymbolCompletionError
		{
			foreach (SourceBuffer item in _source_buffers) {
				if (item.name == name) {
					remove_source_buffer (item);
					return;
				}
			}

			throw new SymbolCompletionError.SOURCE_BUFFER ("source not found");
		}

		public bool contains_source_buffer (SourceBuffer source)
		{
			return contains_source_buffer_by_name (source.name);
		}

		public bool contains_source_buffer_by_name (string name)
		{
			bool result = false;

			lock (_sec_context) {
				foreach (SourceBuffer item in _source_buffers) {
					if (item.name == name) {
						result = true;
						break;
					}
				}
			}
			return result;
		}

		public void remove_source_buffer (SourceBuffer source)
		{
			lock (_sec_context) {
				_source_buffers.add (source);
			}
			schedule_parse_source_buffers ();
		}

		public void reparse_source_buffers ()
		{
			schedule_parse_source_buffers ();
		}

		public bool is_cache_building ()
		{
			bool result = false;

			result = need_parse_pri_context > 0 || need_parse_sec_context > 0;
			return result;
		}

		public void reparse (bool all_context)
		{
			schedule_parse_source_buffers ();
			if (all_context) {
				schedule_parse ();
			}
		}

		private void schedule_parse_source_buffers ()
		{
			//scheduling parse for secondary context
			if (AtomicInt.compare_and_exchange (ref need_parse_sec_context, 0, 1)) {
				debug ("PARSE SECONDARY  CONTEXT SCHEDULED, AND THREAD CREATED");
				create_sec_thread ();
			} else {
				debug ("PARSE SECONDARY CONTEXT SCHEDULED");
				AtomicInt.inc (ref need_parse_sec_context);
			}
		}

		private void schedule_parse ()
		{
			//scheduling parse for primary context
 			if (AtomicInt.compare_and_exchange (ref need_parse_pri_context, 0, 1)) {
				debug ("PARSE PRIMARY CONTEXT SCHEDULED, AND THREAD CREATED");
				create_pri_thread ();
			} else {
				debug ("PARSE PRIMARY CONTEXT SCHEDULED");
				AtomicInt.inc (ref need_parse_pri_context);
			}
		}

		private void* parse_pri_contexts ()
		{
			debug ("PARSER THREAD ENTER");
			Gdk.threads_enter ();
			this.cache_building ();
			Gdk.threads_leave ();

			while (true) {
				int stamp = AtomicInt.get (ref need_parse_pri_context);
				debug ("PARSING PRIMARY CONTEXT: START");
				parse ();
				debug ("PARSING PRIMARY CONTEXT: END");
				//check for changes
				if (AtomicInt.compare_and_exchange (ref need_parse_pri_context, stamp, 0)) {
					break;
				}
			}

			Gdk.threads_enter ();
			this.cache_builded ();
			Gdk.threads_leave ();
			debug ("PARSER THREAD EXIT");
			return ((void *) 0);
		}

		private void* parse_sec_contexts ()
		{
			debug ("PARSER SEC THREAD ENTER");
			Gdk.threads_enter ();
			this.cache_building ();
			Gdk.threads_leave ();

			while (true) {
				int stamp = AtomicInt.get (ref need_parse_sec_context);
				debug ("PARSING SEC CONTEXT: START");
				parse_source_buffers ();
				debug ("PARSING SEC CONTEXT: END");
				//check for changes
				if (AtomicInt.compare_and_exchange (ref need_parse_sec_context, stamp, 0)) {
					break;
				}
			}

			Gdk.threads_enter ();
			this.cache_builded ();
			Gdk.threads_leave ();
			debug ("PARSER SEC THREAD EXIT");
			return ((void *) 0);
		}

		private void parse_source_buffers ()
		{
			var current_context = new CodeContext ();
			lock (_sec_context) {
				SourceFile source;

				source = new SourceFile (current_context, glib_file, true);
				current_context.add_source_file (source);
			
				foreach (SourceBuffer src in _source_buffers) {
					if (src.name != null && src.source != null) {
						var name = src.name;

						if (!name.has_suffix (".vala")) {
							name = "%s.vala".printf (name);
						}
						source = new SourceFile (current_context, name, false, src.source);
						source.add_using_directive (new UsingDirective (new UnresolvedSymbol (null, "GLib", null)));
						current_context.add_source_file (source);
					}
				}
			}

			parse_context (current_context);
			bool need_reparse = false;
			//add new namespaces to standard context)
			foreach (SourceFile src in current_context.get_source_files ()) {
				foreach (UsingDirective nr in src.get_using_directives ()) {
					try {
						if (nr.namespace_symbol.name != null && nr.namespace_symbol.name != "") {
							need_reparse = add_package_from_namespace (nr.namespace_symbol.name, false);
						}
					} catch (Error err) {
						warning ("Error adding namespace %s from file %s", nr.namespace_symbol.name, src.filename);
					}
				}
			}

			lock (_sec_context) {
				_sec_context = current_context;
				//primary context reparse?
				if (need_reparse) {
					schedule_parse ();
				}
			}
		}

		private void parse ()
		{
			var current_context = new CodeContext ();

			lock (_pri_context) {
				SourceFile source;
				foreach (string item in _packages) {
					debug ("adding package %s", item);
					source = new SourceFile (current_context, item, true);
					current_context.add_source_file (source);
				}
				foreach (string item in _sources) {
					source = new SourceFile (current_context, item, false);
					current_context.add_source_file (source);
				}
			}
			parse_context (current_context);
			analyze_context (current_context);

			lock (_pri_context) {
				_pri_context = current_context;
			}
		}

		public void parse_context (CodeContext context)
		{
			context.assert = false;
			context.checking = false;
			context.non_null = false;
			context.non_null_experimental = false;
			context.compile_only = true;

			int glib_major = 2;
			int glib_minor = 12;
			context.target_glib_major = glib_major;
			context.target_glib_minor = glib_minor;

			var parser = new Parser ();
			parser.parse (context);
		}

		private void analyze_context (CodeContext context)
		{
			var attributeprocessor = new AttributeProcessor ();
			attributeprocessor.process (context);

			var symbol_resolver = new SymbolResolver ();
			symbol_resolver.resolve (context);

			var semantic = new SemanticAnalyzer ();
			semantic.analyze (context);
		}

		private SourceFile? find_sourcefile (CodeContext context, string sourcefile)
		{
			string name;

			if (!sourcefile.has_suffix (".vala"))
				name = "%s.vala".printf (sourcefile);
			else
				name = sourcefile;

			foreach (SourceFile source in context.get_source_files ()) {
				if (source.filename == name) {
					return source;
				}
			}

			return null;
		}

		private Class? find_class (SourceFile source, int line, int column) throws SymbolCompletionError
		{
			foreach (CodeNode node in source.get_nodes ()) {
				if (node is Class && node_contains_position (node, line, column)) {
					return (Class) node;
				}
			}

			return null;
		}

		private CodeNode? find_sub_codenode (CodeNode node, int line, int column)
		{
			CodeNode? result = null;

			if (node is Method) {
				var md = (Method) node;

				foreach (CodeNode subnode in md.body.get_statements ()) {
					debug ("checkin subnode %s: %s", Reflection.get_type_from_instance (subnode).name (), subnode.to_string ());
		
					result = find_sub_codenode (subnode, line, column);
					if (result != null) {
						return result;
					}
				}

				if (node_contains_position (md.body, line, column) ||
				    node_contains_position (md, line, column)) {
					return md;
				}
			} else if (node is ExpressionStatement) {
				result = find_sub_codenode (((ExpressionStatement) node).expression, line, column);
				if (result != null)
					return result;
			} else if (node is LambdaExpression) {
				var lambda = (LambdaExpression) node;

 				if (node_contains_position (lambda.statement_body, line, column)) {
					result = find_sub_codenode (lambda.statement_body, line, column);
					if (result != null) {
						return result;
					}
					return lambda;
				}
			} else if (node is Assignment) {

					result = find_sub_codenode (((Assignment) node).right, line, column);
					if (result != null) {
						return result;
					}

 				if (node_contains_position (((Assignment) node).right, line, column)) {
					return node;
				}
			} else if (node is ForeachStatement) {
 				if (node_contains_position (((ForeachStatement) node).body, line, column)) {
					result = find_sub_codenode (((ForeachStatement) node).body, line, column);
					if (result != null) {
						return result;
					}
					return node;
				}
 			} else if (node is WhileStatement) {
 				if (node_contains_position (((WhileStatement) node).body, line, column)) {
					result = find_sub_codenode (((WhileStatement) node).body, line, column);
					if (result != null) {
						return result;
					}
					return node;
				}
 			} else if (node is ForStatement) {
				if (node_contains_position (((ForStatement) node).body, line, column)) {
					result = find_sub_codenode (((ForStatement) node).body, line, column);
					if (result != null) {
						return result;
					}
					return node;
				}
 			} else if (node is Block) {
				if (node_contains_position (node, line, column)) {
					return node;
				}
			} else if (node is ReturnStatement || node is DeclarationStatement || node is InvocationExpression) {
				return null;
			} else {
				warning ("incomplete support for %s", Reflection.get_type_from_instance (node).name ());
			}

			return null;
		}

		private CodeNode? find_codenode (SourceFile source, int line, int column, out Class cl) throws SymbolCompletionError
		{
			CodeNode? result = null;
			cl = null;
			foreach (CodeNode node in source.get_nodes ()) {
				if (node is Method) {
					result = find_sub_codenode (node, line, column);
					if (result != null)
						break;
				} else if (node is Class) {
					debug ("class ehererere");
					cl = (Class) node;
					if (cl.constructor != null) {
						if (node_contains_position (cl.constructor, line, column)) {
							return cl.constructor;
						}
						if (node_contains_position (cl.constructor.body, line, column)) {
							return cl.constructor;
						}
					}

					if (cl.destructor != null) {
						if (node_contains_position (cl.destructor, line, column)) {
							return cl.destructor;
						}
						if (node_contains_position (cl.destructor.body, line, column)) {
							return cl.destructor;
						}
					}

					foreach (Method md in cl.get_methods ()) {
						result = find_sub_codenode (md, line, column);
						if (result != null)
							break;
					}
				}
			}
			return result;
		}

		public DataType? get_datatype_for_name (string symbolname, string sourcefile, int line, int column) throws SymbolCompletionError
		{
			DataType? result = null;
			string[] toks = symbolname.split (".", 2);
			int count = 0;

			while (toks[count] != null)
				count++;

			SourceFile source = null;

			lock (_sec_context) {
				lock (_pri_context) {
					source = find_sourcefile (_sec_context, sourcefile);
					if (source != null) {
						//first local
						result = get_datatype_for_name_with_context (_sec_context, toks[0], source, line, column);
					} else {
						warning ("no sourcefile found %s", sourcefile);
					}

					if (result != null && source != null && count > 1) {
						result = get_inner_datatype (result, toks[1], source);
					}
				}
			}
			return result;
		}

		private DataType? get_inner_datatype (DataType datatype, string fields_path, SourceFile source) throws SymbolCompletionError
		{
			string typename;

			if (datatype is Vala.ClassType) {
				typename = ((Vala.ClassType) datatype).class_symbol.name;
			} else {
				typename = datatype.to_qualified_string ();
			}
			if (typename.has_suffix ("?")) {
				typename = typename.substring (0, typename.length - 1);
			}

			string qualified_type = "%s.%s".printf (typename, fields_path);
			return get_datatype_for_symbol_name (qualified_type, source);
		}

		private DataType? get_datatype_for_symbol_name (string qualified_type, SourceFile source) throws SymbolCompletionError
		{
			Symbol? result = null;

			string[] fields = qualified_type.split (".");
			int count = 0;

			while (fields[count] != null)
				count++;

			Symbol? parent = null;
			bool both_pri_context_scope = true;

			//first on the local context
			for (int idx = 0; idx < count; idx++) {
				if (both_pri_context_scope) {
					result = get_symbol_with_context (_sec_context, fields[idx], source, parent);
				}

				if (result == null || parent != null) {
					both_pri_context_scope = false;
					result = get_symbol_with_context (_pri_context, fields[idx], source, parent);
					if (result == null) {
						break;
					}
				}

				parent = result;
			}

			if (result != null) {
				if (result is Class) {
					return new ClassType ((Class) result);
				} else if (result is Field) {
					var field = (Field) result;
					return field.field_type;
				} else if (result is Property) {
					var prop = (Property) result;
					return prop.property_type;
				} else if (result is Struct) {
					return new ValueType ((Struct) result);
				} else if (result is Method) {
					var method = (Method) result;
					return method.return_type;
				} else {
					throw new SymbolCompletionError.UNSUPPORTED_TYPE ("find_inner_datatype: unsupported type");
				}
			}

			return null;
		}


		private bool using_contains (SourceFile source, string name)
		{
			foreach (UsingDirective ns in source.get_using_directives ()) {
				if (ns.namespace_symbol.name == name) {
					return true;
				}
			}

			return false;
		}

		private Symbol? get_symbol_with_context (CodeContext context, string name, SourceFile source, Symbol? parent = null) throws SymbolCompletionError
		{
			Symbol result = null;
			if (context == null) {
				critical ("context is null");
				return result;
			}

			if (parent == null) {
				//search in all namespaces
				foreach (Namespace ns in context.root.get_namespaces ()) {
					if (ns.name == name) {
						return ns;
					}
				}

				//it isn't a namespace so search for
				//it in all namespaces specified in
				//the using directives
				foreach (Namespace ns in context.root.get_namespaces ()) {
					//if (using_contains (source, ns.name)) {
						result = get_symbol_with_context (context, name, source, ns);
						//}
				}

				if (result == null) {
					//and in the root one
					result = get_symbol_with_context (context, name, source, context.root);
				}

			} else if (parent is Namespace) {
				//find in all classes
				var ns = (Namespace) parent;

 				foreach (Vala.Field item in ns.get_fields ()) {
					if (item.name == name) {
						return item;
					}
				}

				foreach (Vala.Class item in ns.get_classes ()) {
					if (item.name == name) {
						return item;
					}
				}

				foreach (Vala.Struct item in ns.get_structs ()) {
					if (item.name == name) {
						return item;
					}
				}
				

				foreach (Vala.Interface item in ns.get_interfaces ()) {
					if (item.name == name) {
						return item;
					}
				}


				foreach (Vala.Method item in ns.get_methods ()) {
					if (item.name == name) {
						return item;
					}
				}


			} else if (parent is Class) {
				result = get_symbol_in_class_with_context (context, (Class) parent, name, source);
			} else if (parent is Struct) {
				result = get_symbol_in_struct_with_context (context, (Struct) parent, name, source);
			} else if (parent is Interface) {
				result = get_symbol_in_interface_with_context (context, (Interface) parent, name, source);
			} else if (parent is Property) {
				var prop = (Property) parent;
				result = get_symbol_with_context (context, prop.property_type.to_qualified_string (), source);
			} else if (parent is Field) {
				var field = (Field) parent;
				result = get_symbol_with_context (context, field.field_type.to_qualified_string (), source);
			} else if (parent is Method) {
				var method = (Method) parent;
				result = get_symbol_with_context (context, method.return_type.to_qualified_string (), source);
			}

			return result;
		}

		private Symbol? get_symbol_in_struct_with_context (CodeContext context, Struct strt, string name, SourceFile source) {
			foreach (Vala.Method item in strt.get_methods ()) {
				if (item.name == name) {
					return item;
				}
			}

			foreach (Vala.Field item in strt.get_fields ()) {
				if (item.name == name) {
					return item;
				}
			}

			return null;
		}

		private Symbol? get_symbol_in_class_with_context (CodeContext context, Class @class, string name, SourceFile source) {
			foreach (Vala.Method item in @class.get_methods ()) {
				if (item.name == name) {
					return item;
				}
			}

			foreach (Vala.Field item in @class.get_fields ()) {
				if (item.name == name) {
					return item;
				}
			}


			foreach (Vala.Property item in @class.get_properties ()) {
				if (item.name == name) {
					return item;
				}
			}


			foreach (Vala.Signal item in @class.get_signals ()) {
				if (item.name == name) {
					return item;
				}
			}

			Symbol? result = null;

			if (!(@class is GLib.Object)) {
				if (@class.base_class is Vala.Class) {
					result = get_symbol_in_class_with_context (context, @class.base_class, name, source);
				}

				if (result == null) {
					foreach (Vala.DataType type in @class.get_base_types ()) {
						if (type is Vala.Interface) {
							debug ("TODO: search in interface");
						} else if (type is Vala.UnresolvedType) {
							Namespace ns = null;
							Class? cl = resolve_class_name (_pri_context, type.to_string (), out ns);
							if (cl != null) {
								result = get_symbol_in_class_with_context (_pri_context, cl, name, source);
							}
						}
					}
				}
			}

			return result;
		}

		private Symbol? get_symbol_in_interface_with_context (CodeContext context, Interface iface, string name, SourceFile source) {
			foreach (Vala.Method item in iface.get_methods ()) {
				if (item.name == name) {
					return item;
				}
			}

			foreach (Vala.Field item in iface.get_fields ()) {
				if (item.name == name) {
					return item;
				}
			}


			foreach (Vala.Property item in iface.get_properties ()) {
				if (item.name == name) {
					return item;
				}
			}


			foreach (Vala.Signal item in iface.get_signals ()) {
				if (item.name == name) {
					return item;
				}
			}
			
			//TODO: base interfaces!?!?
			return null;
		}

 		private DataType? get_datatype_for_name_with_context (CodeContext context, string symbolname, SourceFile? source = null, int line = 0, int column = 0) throws SymbolCompletionError
		{
			debug ("find datatype");
			Class cl = null;
			var codenode = find_codenode (source, line, column, out cl);
			if (cl != null) {
				debug ("class is %s", cl.name);
			}
			if (codenode != null) {
				debug ("node found %s", codenode.to_string ());
				if (symbolname != "this" && symbolname != "base") {
					Block body = null;

					if (codenode is Method) {
						body = ((Method) codenode).body;
					} else if (codenode is Constructor) {
						body = ((Constructor) codenode).body;
					} else if (codenode is Destructor) {
						body = ((Destructor) codenode).body;
					} else if (codenode is LambdaExpression) {
						body = ((LambdaExpression) codenode).statement_body;
					} else if (codenode is ForeachStatement) {
						body = ((ForeachStatement) codenode).body;
					} else if (codenode is ForStatement) {
						body = ((ForStatement) codenode).body;
					} else if (codenode is WhileStatement) {
						body = ((WhileStatement) codenode).body;
					} else if (codenode is Block) {
						body = (Block) codenode;
					} else {
						throw new SymbolCompletionError.UNSUPPORTED_TYPE ("unsupported type %s", Reflection.get_type_from_instance (codenode).name ());
					}
					//method local vars
					foreach (LocalVariable lvar in body.get_local_variables ()) {
						if (lvar.name == symbolname) {
							if (lvar.variable_type == null && lvar.initializer != null && lvar.initializer.value_type != null) {
								return lvar.initializer.value_type;
							} else
								return lvar.variable_type;
						}
					}


					foreach (Statement st in body.get_statements ()) {
						if (st is DeclarationStatement) {
							var decl = (DeclarationStatement) st;
							debug ("decl %s %s",  Reflection.get_type_from_instance (decl.declaration).name (), decl.declaration.name);	
							if (decl.declaration.name == symbolname) {
								if (decl.declaration is LocalVariable) {
									var lv = (LocalVariable) (decl.declaration);
									if (lv.variable_type == null && lv.initializer != null) {
										DataType vt = lv.initializer.value_type;
										Expression initializer = lv.initializer;

										if (initializer is ObjectCreationExpression) {
											var oce = (((ObjectCreationExpression) (lv.initializer)));
											if (oce.member_name is MemberAccess) {
												initializer = oce.member_name;
											}
										} else if (initializer is InvocationExpression) {
											var invoc = (InvocationExpression) initializer;
											debug ("invocation %s", Reflection.get_type_from_instance (invoc.call).name ());
											initializer = invoc.call;
										}

										if (initializer is MemberAccess) {
											Namespace dummy;
											string class_name;
											var ma = (MemberAccess) initializer;

											class_name = ma.member_name;
											if (ma.inner != null) {
												class_name = ma.inner.to_string ();
											}

											debug ("class name: %s", class_name);
											var cl = resolve_class_name (context, class_name, out dummy);
											
											//don't parse twice the primary context
											if (cl == null && context != _pri_context) { 
												cl = resolve_class_name (_pri_context, class_name, out dummy);
											}
											if (cl != null) {
												debug ("class type %s", cl.name);
												vt = new ClassType (cl);
											} else {
												//not solved!
												var mdt = get_datatype_for_name_with_context (context, class_name, source, line, column);
												if (mdt == null) {
													//try to see if is a namespace
													vt = get_datatype_for_symbol_name ("%s.%s".printf (class_name, ma.member_name), source);
												} else {
													//now locking for the inner datatype
													debug ("find inner for: %s", ma.member_name);
													vt = get_inner_datatype (mdt, ma.member_name, source);
												}
											}
										} else {
											warning ("Type '%s' is not yet supported", Reflection.get_type_from_instance (initializer).name ());
										}
										return vt;
									} else if (lv.variable_type != null) {
										return lv.variable_type;;
									}
								} else {
									throw new SymbolCompletionError.UNSUPPORTED_TYPE ("unsupported type exception");
								}
							}
						}
					}

					if (codenode is Method) {
						//method arguments
						foreach (FormalParameter par in ((Method) codenode).get_parameters ()) {
							if (par.name == symbolname) {
								return par.parameter_type;
							}
						}
					}
				}

				if (cl != null) {
					if (symbolname == "this")
						return new ClassType (cl);
					else if (symbolname == "base") {
						if (cl.base_class != null) {
							return new ClassType (cl.base_class);
						} else {
							foreach (Vala.DataType type in cl.get_base_types ()) {
								if (!(type is Vala.Interface)) {
									//this is a HACK!
									//datatype can be UnreferencedType even for interfaces
									return type;
								}
							}
							return null;
						}
					}

					//field class
					foreach (Field field in cl.get_fields ()) {
						if (field.name == symbolname) {
							return field.field_type;
						}
					}

					//properties
					foreach (Property prop in cl.get_properties ()) {
						if (prop.name == symbolname) {
							return prop.property_type;
						}
					}

					//methods
					foreach (Method clmt in cl.get_methods ()) {
						if (clmt.name == symbolname) {
							return clmt.return_type;
						}
					}

				}
			} else {
				var cl = find_class (source, line, column);
			}
			
			return null;
		}

		private bool node_contains_position (CodeNode node, int line, int column)
		{
			/*
			debug ("search (%d,%d) vs (%d,%d) - (%d,%d)",
			    line, column,
			    node.source_reference.first_line,
			    node.source_reference.first_column,
			    node.source_reference.last_line,
			    node.source_reference.last_column);
			*/

			if ((node.source_reference.first_line < line &&
				node.source_reference.last_line > line) ||
			    (node.source_reference.first_line == line && 
				node.source_reference.first_column <= column) ||
			    (node.source_reference.last_line == line && 
				node.source_reference.last_column <= column)) {
				return true;
			}

			return false;
		}

		public SymbolCompletionResult get_completions_for_name (SymbolCompletionFilterOptions options, string symbolname) throws GLib.Error
		{
			SymbolCompletionResult result;

			lock (_sec_context) {
				result = get_completions_for_name_with_context (options, _sec_context, symbolname);
			}

			if (result.is_empty) {
				lock (_pri_context) {
					result = get_completions_for_name_with_context (options, _pri_context, symbolname);
				}
			}

			return result;
		}

		private SymbolCompletionResult get_completions_for_name_with_context (SymbolCompletionFilterOptions options, CodeContext? context, string symbolname) throws GLib.Error
		{
			var result = new SymbolCompletionResult ();
			if (context == null) {
				critical ("context is null");
				return result;
			}
			string[] toks = symbolname.split (".");
			int count = 0;
			while (toks[count] != null)
				count++;

			string to_find;
			int baseidx = 0;
			Namespace root_ns = null;

			//first try to see if the first token is a namespace name
			foreach (Namespace ns in context.root.get_namespaces ()) {
				if (ns.name == toks[0]) {
					baseidx = 1;
					root_ns = ns;
					break;
				}
			}

			count -= baseidx;

			if (count > 0) {
				if (root_ns == null) {
					foreach (Namespace ns in context.root.get_namespaces ()) {
						get_completions_in_namespace (context, options, toks, count, baseidx, ns, result);
					}
				} else {
					get_completions_in_namespace (context, options, toks, count, baseidx, root_ns, result);
				}

				//fallback to the root namespace
				if (result.is_empty) {
					get_completions_in_namespace (context, options, toks, count, baseidx, context.root, result);
				}
			}
			return result;
		}

		private void get_completions_in_namespace (CodeContext context, SymbolCompletionFilterOptions options, string[] toks, int count, int baseidx, Namespace ns, SymbolCompletionResult result) //throws GLib.Error
		{
			Struct last_st;
			Class last_cl;
			Interface last_if;
			Method last_md;
			Field last_fd;

			foreach (Vala.Struct st in ns.get_structs ()) {
				if (count <= 1 && st.name.has_prefix (toks[baseidx])) {
					last_st = st;
					result.structs.add (new SymbolCompletionItem.with_struct (st));
				} else if (count == 2 && st.name == toks[baseidx]) {
					last_st = st;
					result.structs.add (new SymbolCompletionItem.with_struct (st));
				}
			}
				
			foreach (Vala.Class cl in ns.get_classes ()) {
				if (count <= 1 && cl.name.has_prefix (toks[baseidx])) {
					last_cl = cl;
					result.classes.add (new SymbolCompletionItem.with_class (cl));
				} else if (count == 2 && cl.name == toks[baseidx]) {
					last_cl = cl;
					result.classes.add (new SymbolCompletionItem.with_class (cl));
				}
			}

			if (options.interface_symbols) {
				foreach (Vala.Interface item in ns.get_interfaces ()) {
					if (count <= 1 && item.name.has_prefix (toks[baseidx])) {
						last_if = item;
						result.interfaces.add (new SymbolCompletionItem.with_interface (item));
					} else if (count == 2 && item.name == toks[baseidx]) {
						last_if = item;
						result.interfaces.add (new SymbolCompletionItem.with_interface (item));
					}
				}
			}

			if (options.static_symbols) {
				foreach (Vala.Method item in ns.get_methods ()) {
					if (count <= 1 && item.name.has_prefix (toks[baseidx])) {
						last_md = item;
						result.methods.add (new SymbolCompletionItem.with_method (item));
					} else if (count == 2 && item.name == toks[baseidx]) {
						last_md = item;
						result.methods.add (new SymbolCompletionItem.with_method (item));
					}
				}
			}

			if (options.static_symbols) {
				foreach (Vala.Field item in ns.get_fields ()) {
					if (count <= 1 && item.name.has_prefix (toks[baseidx])) {
						last_fd = item;
						result.fields.add (new SymbolCompletionItem.with_field (item));
					} else if (count == 2 && item.name == toks[baseidx]) {
						last_fd = item;
						result.fields.add (new SymbolCompletionItem.with_field (item));
					}
				}
			}

			//if I've found just one type
			if (count >= 1 && result.classes.size == 1 && result.classes[0].name == toks[baseidx]) {
				find_name_in_class (context, options, count == 1 ? null : toks[baseidx+1], last_cl, result);
			} else if (count >= 1 && result.structs.size == 1 && result.structs[0].name == toks[baseidx]) {
				find_name_in_struct (context, options, count == 1 ? null : toks[baseidx+1], last_st, result);
			} else if (count >= 1 && result.interfaces.size == 1 && result.interfaces[0].name == toks[baseidx]) {
				find_name_in_interface (context, options, count == 1 ? null : toks[baseidx+1], last_if, result);
			}

			if (options.exclude_type != null && result.classes.size == 1 && options.exclude_type == result.classes[0].name) {
				result.classes.remove_at (0);
			} else if (options.exclude_type != null && result.structs.size == 1 && options.exclude_type == result.structs[0].name) {
				result.structs.remove_at (0);
			} else if (options.exclude_type != null && result.interfaces.size == 1 && options.exclude_type == result.interfaces[0].name) {
				result.interfaces.remove_at (0);
			}
		}

		private bool list_contains_string (Gee.List<string> list, string @value)
		{
			foreach (string current in list) {
				if (current == @value)
					return true;
			}

			return false;
		}

		private void find_name_in_class (CodeContext context, SymbolCompletionFilterOptions options, string? name, Vala.Class item, SymbolCompletionResult result)
		{
			foreach (Vala.Method method in item.get_methods ()) {
				if (test_symbol (options, name, method) &&
				    (options.static_symbols || (options.static_symbols == false && method.binding != MemberBinding.STATIC))) {
					if (options.only_constructors && (method is Constructor || method.name.has_prefix(".new"))) {
						result.methods.add (new SymbolCompletionItem.with_method (method));
					} else if (!options.only_constructors) {
						result.methods.add (new SymbolCompletionItem.with_method (method));
					}
				}
			}

			if (!options.only_constructors) {
				foreach (Vala.Field field in item.get_fields ()) {
					if (test_symbol (options, name, field) &&
					    (options.static_symbols || (options.static_symbols == false && field.binding != MemberBinding.STATIC))) {
						result.fields.add (new SymbolCompletionItem.with_field (field));
					}
				}


				foreach (Vala.Property property in item.get_properties ()) {
					if (test_symbol (options, name, property)) {
						result.properties.add (new SymbolCompletionItem.with_property (property));
					}
				}


				foreach (Vala.Signal @signal in item.get_signals ()) {
					if (test_symbol (options, name, @signal)) {
						result.signals.add (new SymbolCompletionItem.with_signal (@signal));
					}
				}
			}

			if (!(item is GLib.Object)) {
				if (item.base_class is Vala.Class) {
					if (!result.classes_contains (item.base_class.name))
						find_name_in_class (context, options, name, item.base_class , result);
				}

				foreach (Vala.DataType type in item.get_base_types ()) {
					if (options.interface_symbols && type is Vala.Interface) {
						if (!result.interfaces_contains (((Vala.Interface) type).name))
							find_name_in_interface (context, options, name, (Vala.Interface) type, result);
					} else if (type is Vala.UnresolvedType) {
						Namespace ns = null;
						Class? cl = resolve_class_name (_pri_context, type.to_string (), out ns);
						if (cl != null) {
							find_name_in_class (_pri_context, options, name, cl , result);
						}
					}
				}
			}
		}

		private Class? resolve_class_name (CodeContext context, string typename, out Namespace? parent_ns = null, string? preferred_namespace = null)
		{
			string[] toks = typename.split (".");
			int count = 0;
			while (toks[count] != null)
				count++;

			Namespace root_ns = null;
			Namespace preferred_ns = null;
			string name = toks[0];

			parent_ns = null;
			if (preferred_namespace != null && preferred_namespace == context.root.name) {
				preferred_ns = context.root;
			}

			//first try to see if the first token is a namespace name
			foreach (Namespace ns in context.root.get_namespaces ()) {
				if (ns.name == name) {
					root_ns = ns;
					name = toks[1];
					break;
				}
				if (preferred_namespace == ns.name) {
					preferred_ns = ns;
				}
			}
			if (root_ns == null) {
				if (preferred_ns != null) {
					foreach (Class cl in preferred_ns.get_classes ()) {
						if (cl.name == name) {
							parent_ns = preferred_ns;
							return cl;
						}
					}		
				}
				foreach (Namespace ns in context.root.get_namespaces ()) {
					if (ns != preferred_ns) {
						foreach (Class cl in ns.get_classes ()) {
							if (cl.name == name) {
								parent_ns = ns;
								return cl;
							}
						}
					}
				}
			}

			// cerco nel ns selezionato
			if (root_ns != null && root_ns != preferred_ns) {
				foreach (Class cl in root_ns.get_classes ()) {
					if (cl.name == name) {
						parent_ns = root_ns;
						return cl;
					}
				}
			}

			//fallback to the root
			//namespace
			if (_pri_context.root != preferred_ns) {
				foreach (Class cl in context.root.get_classes ()) {
					if (cl.name == name) {
						parent_ns = context.root;
						return cl;
					}
				}
			}

			return null;
		}

		private bool test_symbol (SymbolCompletionFilterOptions options, string? name, Symbol symbol)
		{
			if ((name == null || symbol.name.has_prefix (name)) &&
			    ((options.public_symbols && symbol.access == Vala.SymbolAccessibility.PUBLIC) ||
				(options.private_symbols && symbol.access == Vala.SymbolAccessibility.PRIVATE) ||
				(options.protected_symbols && symbol.access == Vala.SymbolAccessibility.PROTECTED) ||
				(options.internal_symbols && symbol.access == Vala.SymbolAccessibility.INTERNAL))) {
				    return true;
			}

			return false;
		}

		private void find_name_in_interface (CodeContext context, SymbolCompletionFilterOptions options, string? name, Vala.Interface item, SymbolCompletionResult result)
		{
			foreach (Vala.Method method in item.get_methods ()) {
				if (test_symbol (options, name, method)) {
					if (options.only_constructors && (method is Constructor || method.name.has_prefix (".new"))) {
						result.methods.add (new SymbolCompletionItem (method.name));
					} else if (!options.only_constructors) {
						result.methods.add (new SymbolCompletionItem (method.name));
					}
				}
			}

			if (!options.only_constructors) {
				foreach (Vala.Field field in item.get_fields ()) {
					if (test_symbol (options, name, field)) {
						result.fields.add (new SymbolCompletionItem (field.name));
					}
				}

				foreach (Vala.Property property in item.get_properties ()) {
					if (test_symbol (options, name, property)) {
						result.properties.add (new SymbolCompletionItem (property.name));
					}
				}


				foreach (Vala.Signal @signal in item.get_signals ()) {
					if (test_symbol (options, name, @signal)) {
						result.signals.add (new SymbolCompletionItem (@signal.name));
					}
				}
			}

			//TODO: prerequisites
		}

		private void find_name_in_struct (CodeContext context, SymbolCompletionFilterOptions options, string? name, Vala.Struct item, SymbolCompletionResult result)
		{
			foreach (Vala.Field field in item.get_fields ()) {
				if (test_symbol (options, name, field)) {
					result.fields.add (new SymbolCompletionItem (field.name));
				}
			}

			foreach (Vala.Method method in item.get_methods ()) {
				if (test_symbol (options, name, method)) {
					result.methods.add (new SymbolCompletionItem (method.name));
				}
			}

		}

		private string? find_vala_package_name (string @namespace) throws GLib.Error
		{
			try {
				//find for: foo.vapi
				//or for: foo-1.0.vapi
				//or for: foo+1.0.vapi
				string[] to_finds = new string[] { "%s.".printf (@namespace.down ()),
								   "%s-".printf (@namespace.down ()),
								   "%s+".printf (@namespace.down ()) };

				foreach (string vapidir in _vapidirs) {
					Dir dir;
					try {					      
						dir = Dir.open (vapidir);
					} catch (FileError err) {
						//do nothing
						continue;
					}
					string? filename = dir.read_name ();
					while (filename != null) {
						if (filename.has_suffix ("vapi")) {
							filename = filename.down ();
							foreach (string to_find in to_finds) {
								if (filename.has_prefix (to_find)) {
									return filename;
								}
							}
						}
						filename = dir.read_name ();
					}
				}
				return null;
			} catch (Error err) {
				throw err;
			}
		}

		private Gee.List<string> find_vala_package_filename (string package_name) throws FileError
		{
			Gee.List<string> results = new Gee.ArrayList<string> ();
			string found_vapidir = null;
			string filename;
			string path;
			if (!package_name.has_suffix (".vapi"))
				filename = "%s.vapi".printf (package_name);
			else
				filename = package_name;

			foreach (string vapidir in _vapidirs) {
				path = "%s/%s".printf (vapidir,filename);

				if (FileUtils.test (path, FileTest.EXISTS)) {
					results.add (path);
					found_vapidir = vapidir;
					break;
				}
			}

			if (results.size > 0) {

				//dependency check
				string dep_file = "%s/%s.deps".printf (found_vapidir, filename.substring (0, filename.length - ".vapi".length));
				if (FileUtils.test (dep_file, FileTest.EXISTS)) {
					size_t len;
					string buffer;
					FileUtils.get_contents (dep_file, out buffer, out len);
					foreach (string dep_name in buffer.split("\n")) {
						if (dep_name.length > 1)
							results.insert (0, "%s/%s.vapi".printf (found_vapidir, dep_name));
					}
				}
			}
			return results;
		}
	}
}

