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
		private ParserManager _parser = new ParserManager ();
		
		public ParserManager parser
		{
			get {
				return _parser;
			}
		}

		public void cleanup ()
		{
			_parser = null;
		}

		private SourceFile? find_sourcefile (CodeContext context, string sourcefile)
		{
			string name;

			if (!sourcefile.has_suffix (".vala"))
				name = "%s.vala".printf (sourcefile);
			else
				name = sourcefile;

			var sources = context.get_source_files ();
			if (sources != null) {
				foreach (SourceFile source in sources) {
					if (source.filename == name) {
						return source;
					}
				}
			}
			return null;
		}

		private Class? get_class (SourceFile source, int line, int column) throws SymbolCompletionError
		{
			foreach (CodeNode node in source.get_nodes ()) {
				debug ("(find_class) node: %s - %s", Reflection.get_type_from_instance (node).name (), node.to_string());
				if (node is Class) {
					var cl = (Class) node;
					//TODO: fields, signal subclasses
					foreach (Method md in cl.get_methods ()) {
						if (find_sub_codenode (md, line, column) != null) {
							return cl;
						}
					}
				}
			}

			return null;
		}

		private CodeNode? find_sub_codenode (CodeNode node, int line, int column)
		{
			CodeNode? result = null;

			if (node is Method) {
				var md = (Method) node;

				result = find_sub_codenode (md.body, line, column);
				if (result != null)
					return result;

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
				var fe = (ForeachStatement) node;

				if (node_contains_position (fe.body, line, column) ||
				    node_contains_position (fe, line, column)) {
					result = find_sub_codenode (fe.body, line, column);
					if (result != null)
						return result;

					return fe;
				}
 			} else if (node is WhileStatement) {
				var ws = (WhileStatement) node;

				if (node_contains_position (ws.body, line, column) ||
				    node_contains_position (ws, line, column)) {
					result = find_sub_codenode (ws.body, line, column);
					if (result != null)
						return result;

					return ws;
				}
 			} else if (node is ForStatement) {
				var fs = (ForStatement) node;

				if (node_contains_position (fs.body, line, column) ||
				    node_contains_position (fs, line, column)) {
					result = find_sub_codenode (fs.body, line, column);
					if (result != null)
						return result;

					return fs;
				}
 			} else if (node is Block) {
				var block = (Block) node;

				//check first in inner sub-nodes
				foreach (CodeNode subnode in block.get_statements ()) {
					result = find_sub_codenode (subnode, line, column);
					if (result != null) {
						return result;
					}
				}
			} else if (node is ReturnStatement || node is DeclarationStatement || node is MethodCall) {
				return null;
			} else if (node is CastExpression) {
				if (node_contains_position (node, line, column)) {
					return node;
				}
			} else {
				//warning ("incomplete support for %s", Reflection.get_type_from_instance (node).name ());
			}

			return null;
		}

		private CodeNode? find_codenode (SourceFile source, int line, int column, out Class cl) throws SymbolCompletionError
		{
			cl = null;
			foreach (CodeNode node in source.get_nodes ()) {
				CodeNode? result = null;
				if (node is Method) {
					result = find_sub_codenode (node, line, column);
					if (result != null)
						return result;
				} else if (node is Class) {
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
							return result;
					}
				}
			}
			cl = null;
			return null;
		}

		public string get_qualified_name_for_datatype (DataType dt)
		{
			string typename;
			
			if (dt is Vala.ClassType) {
				typename = ((Vala.ClassType) dt).class_symbol.get_full_name ();
			} else {
				typename = dt.to_qualified_string ();
			}
			if (typename.has_suffix ("?")) {
				typename = typename.substring (0, typename.length - 1);
			}
			return typename;
		}
		
		public Gee.List<SymbolCompletionItem> get_methods_for_source (string sourcefile)
		{
			warn_if_fail (_parser != null);
			SourceFile source = null;
			var results = new Gee.ArrayList<SymbolCompletionItem> ();
			
			if (sourcefile != null) {
				_parser.lock_all_contexts ();
				source = find_sourcefile (_parser.sec_context, sourcefile);
				if (source == null)
					source = find_sourcefile (_parser.pri_context, sourcefile);
				
				if (source != null) {
					var ml = new MethodList (results);
					source.accept (ml);
				}
				_parser.unlock_all_contexts ();
			}
			return results;
		}
		
		public string get_datatype_name_for_name (string symbolname, string sourcefile, int line, int column) throws SymbolCompletionError
		{
			string typename = null;
			var timer = new Timer ();
			timer.start ();
			var dt = get_datatype_for_name (symbolname, sourcefile, line, column);
			timer.stop ();
			
			GLib.debug ("(get_datatype_name_for_name) time elapsed: %f", timer.elapsed ());
			if (dt != null) {
				typename = get_qualified_name_for_datatype (dt);
				debug ("(get_datatype_name_for_name) found DataType: %s", typename);
			}
			return typename;
		}
		
		public DataType? get_datatype_for_name (string symbolname, string sourcefile, int line, int column) throws SymbolCompletionError
		{
			warn_if_fail (_parser != null);
			DataType? result = null;
			string[] toks = symbolname.split (".", 2);
			int count = 0;

			while (toks[count] != null)
				count++;

			SourceFile source = null;

			_parser.lock_all_contexts ();
			source = find_sourcefile (_parser.sec_context, sourcefile);
			if (source != null) {
				//first local
				result = get_datatype_for_name_with_context (_parser.sec_context, toks[0], source, line, column);
			} else {
				warning ("(get_datatype_for_name) no sourcefile found %s", sourcefile);
			}

			if (result != null && source != null && count > 1) {
				result = get_inner_datatype (result, toks[1], source);
			}
			_parser.unlock_all_contexts ();
			return result;
		}

		private DataType? get_inner_datatype (DataType datatype, string fields_path, SourceFile source) throws SymbolCompletionError
		{
			string qualified_type = "%s.%s".printf (get_qualified_name_for_datatype (datatype), fields_path);
			
			return get_datatype_for_symbol_name (qualified_type, source);
		}

		private DataType? get_datatype_for_symbol_name (string qualified_type, SourceFile source) throws SymbolCompletionError
		{
			warn_if_fail (_parser != null);
			Symbol? result = null;

			string[] fields = qualified_type.split (".");
			int count = 0;

			while (fields[count] != null)
				count++;

			Symbol? parent = null;
			bool search_both_contexts = true;

			//first on the local context
			for (int idx = 0; idx < count; idx++) {
				if (search_both_contexts) {
					result = get_symbol_with_context (_parser.sec_context, fields[idx], source, parent);
				}

				if (result == null || parent != null) {
					search_both_contexts = false;
					result = get_symbol_with_context (_parser.pri_context, fields[idx], source, parent);
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
					throw new SymbolCompletionError.UNSUPPORTED_TYPE ("(get_datatype_for_symbol_name): unsupported type");
				}
			}

			return null;
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
			warn_if_fail (_parser != null);
			if (_parser == null)
				return null;

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
							Class? cl = resolve_class_name (_parser.pri_context, type.to_string (), out ns);
							if (cl != null) {
								result = get_symbol_in_class_with_context (_parser.pri_context, cl, name, source);
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
			DataType type = null;

			debug ("(get_datatype_for_name_with_context) find datatype %s", symbolname);
			Class cl = null;
			var codenode = find_codenode (source, line, column, out cl);
			if (cl != null) {
				debug ("class is %s, %s", cl.name, cl.get_full_name ());
			}
			if (codenode != null) {
				debug ("(get_datatype_for_name_with_context) node found %s", codenode.to_string ());
				if (symbolname != "this" && symbolname != "base") {
					Block body = null;

					if (codenode is Method) {
						body = ((Method) codenode).body;
					} else if (codenode is CreationMethod) {
						body = ((Constructor) codenode).body;
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
						throw new SymbolCompletionError.UNSUPPORTED_TYPE ("(get_datatype_for_name_with_context) unsupported type %s", Reflection.get_type_from_instance (codenode).name ());
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
							//debug ("decl %s %s",  Reflection.get_type_from_instance (decl.declaration).name (), decl.declaration.name);	
							if (decl.declaration.name == symbolname) {
								if (decl.declaration is LocalVariable) {
									type = datatype_for_localvariable (context, source, line, column, (LocalVariable) (decl.declaration));
									if (type != null)
										return type;
								} else {
									warning ("(get_datatype_for_name_with_context) unsupported type");
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
					} else if (codenode is ForeachStatement) {
						var fe = (ForeachStatement) codenode;
						//foreach statement iterator
						if (fe.variable_name == symbolname) {
							return fe.type_reference;
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
				cl = get_class (source, line, column);
			}
			
			return null;
		}

		private DataType datatype_for_localvariable (CodeContext context,  SourceFile? source = null, int line = 0, int column = 0, LocalVariable lv)
		{
			warn_if_fail (parser != null);
			DataType vt = null;
			try {
				if (lv.variable_type == null && lv.initializer != null) {
					vt = lv.initializer.value_type;
					if (vt == null) {
						Expression initializer = lv.initializer;
						string class_name = null;
						string member_name = null;

						if (initializer is ObjectCreationExpression) {
							var oce = (((ObjectCreationExpression) (lv.initializer)));
							if (oce.member_name is MemberAccess) {
								initializer = oce.member_name;
							}
						} else if (initializer is MethodCall) {
							var invoc = (MethodCall) initializer;
							initializer = invoc.call;
						}
						
						if (initializer is MemberAccess) {
							var ma = (MemberAccess) initializer;
							
							if (ma.inner != null) {
								class_name = ma.inner.to_string ();
							}
							
							member_name = ma.member_name;
						} else if (initializer is CastExpression) {
							var ce = (CastExpression) initializer;
							vt = ce.type_reference;
						} else {
							warning ("(datatype_for_localvariable) initializer of type '%s' is not yet supported", Reflection.get_type_from_instance (initializer).name ());
						}
						
						if (class_name != null) {
							debug ("(datatype_for_localvariable) find datatype for class name: %s", class_name);
							Namespace dummy;
							var cl = resolve_class_name (context, class_name, out dummy);
							
							//don't parse twice the primary context
							if (cl == null && context != _parser.pri_context) { 
								cl = resolve_class_name (_parser.pri_context, class_name, out dummy);
							}
							if (cl != null) {
								debug ("(datatype_for_localvariable) class type %s", cl.name);
								vt = new ClassType (cl);
							}
						}
						
						if (vt == null && member_name != null) {
							//try to find the current class
							var cl = get_class (source, line, column);
							if (cl != null) {
								vt = get_inner_datatype (new ClassType (cl), member_name, source);
							} else {
								//not solved!
								var mdt = get_datatype_for_name_with_context (context, member_name, source, line, column);
								if (mdt != null) {
									//now locking for the inner datatype
									debug ("(datatype_for_localvariable) find inner for: %s, %s", this.get_qualified_name_for_datatype (mdt), member_name);
									vt = get_inner_datatype (mdt, member_name, source);
								}
							}
						}
					}
				} else if (lv.variable_type != null) {
					vt = lv.variable_type;;
				}
			} catch (Error err) {
				warning ("error in datatype_for_localvariable: %s", err.message);
			}
			return vt;
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
		
		private string normalize_typename (string typename, string namespace_name)
		{
			debug ("(normalize_typename): %s, namespace %s", typename, namespace_name);
			
			if (typename.has_prefix ("%s.".printf (namespace_name))) {
				return typename;				
			} else {
				return "%s.%s".printf (namespace_name, typename);
			}			
		}
		
		public SymbolCompletionResult get_completions_for_name (SymbolCompletionFilterOptions options, string symbolname, string? sourcefile = null) throws GLib.Error
		{
			warn_if_fail (_parser != null);
			SymbolCompletionResult result = new SymbolCompletionResult ();
			SourceFile source = null;

			
			if (sourcefile != null) {
				source = find_sourcefile (_parser.sec_context, sourcefile);
			}
			
			//first look in the namespaces defined in the source file
			_parser.lock_all_contexts ();
			var finder = new TypeFinderVisitor (source,  _parser.pri_context);
			var completion = new CompletionVisitor (options, result, source,  _parser.pri_context);
			if (source != null) {
				foreach (CodeNode node in source.get_nodes ()) {
					if (node is Namespace) {
						var ns = (Namespace) node;
						var name = normalize_typename (symbolname, ns.name);
						GLib.debug ("source: search in secondary namespaces for %s", name);
						finder.searched_typename = name;
						finder.visit_namespace (ns);
						if (finder.result != null) {
							GLib.debug ("source: search in secondary namespaces found: %s", finder.qualified_typename);
							finder.result.accept (completion);
							if (finder.result is Namespace) {
								get_completion_for_name_in_namespace_with_context (ns.name, name, 
									finder, completion, _parser.pri_context);
							}
							break;
						} else {
							GLib.debug ("source: search in primary namespaces for %s", name);
							int tmp = result.count;
							get_completion_for_name_in_namespace_with_context (ns.name, name, 
								finder, completion, _parser.pri_context);
							if (tmp != result.count) {
								GLib.debug ("source: search in primary namespaces found: %s", name);
								break; //found something in primary context
							}
						}
					}
				}					
			} else {
				GLib.debug ("no source file found");
			}

			if (finder.result == null) {
				//search it in the root namespace, string and other base types are there
				GLib.debug ("search in primary root namespace for %s", symbolname);
				finder.searched_typename = symbolname;
				finder.visit_namespace (_parser.pri_context.root);
				if (finder.result != null) {
					finder.result.accept (completion);
				}
			}
			
			//search it in referenced namespaces
			if (source != null && finder.result == null) {
				foreach(UsingDirective item in source.get_using_directives ()) {
					GLib.debug ("using directives: search in primary with namespace  %s for %s", item.namespace_symbol.name, symbolname);
					int tmp = result.count;
					get_completion_for_name_in_namespace_with_context (item.namespace_symbol.name, 
						symbolname, finder, completion, _parser.pri_context);
					if (tmp != result.count) {
						break;
					}
				}
			}

			_parser.unlock_all_contexts ();
			return result;
		}
		
		private void get_completion_for_name_in_namespace_with_context (string namespace_name, string typename, TypeFinderVisitor finder, CompletionVisitor completion, CodeContext context)
		{
			foreach (Namespace ns in context.root.get_namespaces ()) {
				if (ns.name == namespace_name) {
					finder.searched_typename = typename;
					finder.visit_namespace (ns);
					if (finder.result != null) {					
						completion.integrate_completion (finder.result);
					}
					break;
				}
			}
		}

		private Namespace? get_namespace_for_name (Namespace root, string name, ref int level)
		{
			Namespace result = null;
			string[] parts = name.split (".",2);
			int count = 0;
			while (parts[count] != null)
				count++;

			if (parts[0] == null || parts[0] == "")
				return null;

			foreach (Namespace ns in root.get_namespaces ()) {
				if (ns.name == parts[0]) {
					level++;
					if (count > 1) {
						result = get_namespace_for_name (ns, parts[1], ref level);
					}
					if (result == null)
						result = ns;
					break;
				}
			}

			return result;
		}

		private Class? resolve_class_name (CodeContext context, string typename, out Namespace? parent_ns = null, string? preferred_namespace = null)
		{
			warn_if_fail (_parser != null);
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
			if (_parser.pri_context.root != preferred_ns) {
				foreach (Class cl in context.root.get_classes ()) {
					if (cl.name == name) {
						parent_ns = context.root;
						return cl;
					}
				}
			}

			return null;
		}		
	}
}

