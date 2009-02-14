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
				if (node is Class) {
					var cl = (Class) node;
					//TODO: fields, signal subclasses
					foreach (Method md in cl.get_methods ()) {
						if (find_sub_codenode (md, line, column, null) != null) {
							return cl;
						}
					}
				}
			}

			return null;
		}

		private CodeNode? find_sub_codenode (CodeNode node, int line, int column, CodeNode? parent_node)
		{
			CodeNode? result = null;
			//this is a HACK since vala set the parent_node property only for expression
			if (parent_node != null && node.parent_node == null && node != parent_node)
				node.parent_node = parent_node;
				
			if (node is Vala.Property) {
				var prop = (Vala.Property) node;
				if (prop.get_accessor != null) {
					result = find_sub_codenode (prop.get_accessor, line, column, node);
					if (result != null)
						return result;
				}
				if (prop.set_accessor != null) {
					result = find_sub_codenode (prop.set_accessor, line, column, node);
					if (result != null)
						return result;						
				}

				if (node_contains_position (prop, line, column))
					return prop;
			} else if (node is Vala.PropertyAccessor) {
				var pa = (Vala.PropertyAccessor) node;
				result = find_sub_codenode (pa.body, line, column, node);
				if (result != null)
					return result;

				if (node_contains_position (pa, line, column)) {
					return pa;
				}
			} else if (node is Constructor) {
				var cs = (Constructor) node;

				result = find_sub_codenode (cs.body, line, column, node);
				if (result != null)
					return result;

				if (node_contains_position (cs.body, line, column) ||
				    node_contains_position (cs, line, column)) {
					return cs;
				}
			} else if (node is Destructor) {
				var ds = (Destructor) node;

				result = find_sub_codenode (ds.body, line, column, node);
				if (result != null)
					return result;

				if (node_contains_position (ds.body, line, column) ||
				    node_contains_position (ds, line, column)) {
					return ds;
				}				
			} else if (node is Method) {
				var md = (Method) node;

				result = find_sub_codenode (md.body, line, column, node);
				if (result != null)
					return result;

				if (node_contains_position (md.body, line, column) ||
				    node_contains_position (md, line, column)) {
					return md;
				}
			} else if (node is TryStatement) {
				var tr = (TryStatement) node;
				result = find_sub_codenode (tr.body, line, column, tr);
				if (result != null)
					return result;

				if (node_contains_position (tr.body, line, column))
					return tr.body;
			
				result = find_sub_codenode (tr.finally_body, line, column, tr); 
				if (result != null)
					return result;

				if (node_contains_position (tr.finally_body, line, column))
					return tr.finally_body;

				foreach (CatchClause clause in tr.get_catch_clauses ()) {
					result = find_sub_codenode (clause, line, column, tr);
					if (result != null)
						return result;
				}

				if (node_contains_position (tr, line, column)) {
					return tr;
				}
			} else if (node is CatchClause) {
				var cc = (CatchClause) node;
				result = find_sub_codenode (cc.body, line, column, cc); 
				if (result != null)
					return result;
					
				if (node_contains_position (cc.body, line, column) ||
				    node_contains_position (cc, line, column)) {
					return cc;
				}
			} else if (node is ExpressionStatement) {
				result = find_sub_codenode (((ExpressionStatement) node).expression, line, column, node);
				if (result != null)
					return result;
			} else if (node is LambdaExpression) {
				var lambda = (LambdaExpression) node;

 				if (node_contains_position (lambda.statement_body, line, column)) {
					result = find_sub_codenode (lambda.statement_body, line, column, node);
					if (result != null) {
						return result;
					}
					return lambda;
				}
			} else if (node is Assignment) {
				result = find_sub_codenode (((Assignment) node).right, line, column, node);
				if (result != null) {
					return result;
				}

 				if (node_contains_position (((Assignment) node).right, line, column)) {
					return node;
				}
			} else if (node is IfStatement) {
				var ifs = (IfStatement) node;
					
				if (ifs.true_statement != null) {
					result = find_sub_codenode (ifs.true_statement, line, column, node);
					if (result != null)
						return result;
				
					if  (node_contains_position (ifs.true_statement, line, column)) {
						return ifs.true_statement;
					}
				}
				if (ifs.false_statement != null) {
					result = find_sub_codenode (ifs.false_statement, line, column, node);
					if (result != null)
						return result;

					if (node_contains_position (ifs.false_statement, line, column)) {
						return ifs.false_statement;
					}
				}

				if (node_contains_position (ifs, line, column))
					return ifs;
			} else if (node is ForeachStatement) {
				var fe = (ForeachStatement) node;
				if (node_contains_position (fe.body, line, column) ||
				    node_contains_position (fe, line, column)) {
					result = find_sub_codenode (fe.body, line, column, node);
					if (result != null) {
						return result;
					}

					return fe;
				}
 			} else if (node is WhileStatement) {
				var ws = (WhileStatement) node;

				if (node_contains_position (ws.body, line, column) ||
				    node_contains_position (ws, line, column)) {
					result = find_sub_codenode (ws.body, line, column, node);
					if (result != null)
						return result;

					return ws;
				}
 			} else if (node is ForStatement) {
				var fs = (ForStatement) node;

				if (node_contains_position (fs.body, line, column) ||
				    node_contains_position (fs, line, column)) {
					result = find_sub_codenode (fs.body, line, column, node);
					if (result != null)
						return result;

					return fs;
				}
 			} else if (node is Block) {
				var block = (Block) node;

				//check first in inner sub-nodes
				foreach (CodeNode subnode in block.get_statements ()) {
					result = find_sub_codenode (subnode, line, column, node);
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
				warning ("incomplete support for %s", Reflection.get_type_from_instance (node).name ());
			}

			return null;
		}

		private CodeNode? find_codenode (SourceFile source, int line, int column, out Class cl, out Method method) throws SymbolCompletionError
		{
			cl = null;
			method = null;
			foreach (CodeNode node in source.get_nodes ()) {
				CodeNode? result = null;
				method = null;
				if (node is Method) {
					method = (Method) node;
					result = find_sub_codenode (node, line, column, null);
					if (result != null)
						return result;
				} else if (node is Class) {
					cl = (Class) node;
					if (cl.constructor != null) {
						result = find_sub_codenode (cl.constructor, line, column, cl);
						if (result != null)
							return result;
					}

					if (cl.destructor != null) {
						result = find_sub_codenode (cl.destructor, line, column, cl);
						if (result != null)
							return result;
					}

					foreach (Method md in cl.get_methods ()) {
						method = (Method) node;
						result = find_sub_codenode (md, line, column, cl);
						if (result != null)
							return result;
					}
					method = null;
					foreach (Property prop in cl.get_properties ()) {
						result = find_sub_codenode (prop, line, column, cl);
						if (result != null)
							return result;
					}					
				}
			}
			cl = null;
			method = null;
			return null;
		}


		public string get_name_for_datatype (DataType dt)
		{
			string typename = get_qualified_name_for_datatype (dt);
			string[] toks = typename.split (".");
			int count = 0;
			while (toks[count+1] != null)
				count++;
				
			return toks[count];
		}

		public string get_qualified_name_for_datatype (DataType dt)
		{
			string? typename;
			
			if (dt is Vala.ClassType) {
				typename = ((Vala.ClassType) dt).class_symbol.get_full_name ();
			} else {
				typename = dt.to_qualified_string ();
			}
			
			if (null == typename){ return ""; }
			
			if (typename.has_suffix ("?")) {
				typename = typename.substring (0, typename.length - 1);
			}
			if (typename.str ("<") != null && typename.has_suffix (">")) {
				//generic type definition. delete the generic part from the typename
				typename = typename.split ("<", 2)[0];
			}
			typename = typename.replace ("[]", "");
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

		public SymbolCompletionResult get_namespaces ()
		{
			warn_if_fail (_parser != null);
			var results = new Gee.ArrayList<SymbolCompletionItem> ();
			var result = new SymbolCompletionResult ();
			
			_parser.lock_all_contexts ();

			try {
				CodeContext? context = (null != _parser.sec_context)? _parser.sec_context: _parser.pri_context;
				
				if (null != context) {
					foreach(Namespace ns in context.root.get_namespaces()) {
						results.add(new SymbolCompletionItem.with_namespace(ns));
					}
				}
			} finally {
				_parser.unlock_all_contexts ();
			}

			result.namespaces = results;
			return result;
		}
		
		public SymbolCompletionResult get_visible_symbols (SymbolCompletionFilterOptions options, string? sourcefile, int line, int column, bool types_only)
		{
			SymbolCompletionResult result = new SymbolCompletionResult ();
			if (null == sourcefile){ return result; }
			
			warn_if_fail (_parser != null);
			
			_parser.lock_all_contexts ();
			try {
				SourceFile? source = find_sourcefile (_parser.sec_context, sourcefile);
				if (null == source){ source = find_sourcefile (_parser.pri_context, sourcefile); }
				if (null == source){ return result; }
				
				// Check root namespace
				Gee.ArrayList<Namespace> namespaces = new Gee.ArrayList<Namespace> ();
				namespaces.add (source.context.root);
				
				// Check included namespaces
				foreach (UsingDirective item in source.get_using_directives ()) {
					namespaces.add ((Namespace)item.namespace_symbol);
				}
				
				// Check the current namespace
				Class? kl;
				Method? method;
				find_codenode (source, line, column, out kl, out method);
				if (null != kl && null != kl.parent_symbol && (kl.parent_symbol is Namespace)) {
					namespaces.add ((Namespace)kl.parent_symbol); 
				}
				
				foreach (Namespace ns in namespaces) {
					foreach (Namespace cl in ns.get_namespaces ()) {
						result.namespaces.add (new SymbolCompletionItem.with_namespace (cl));
					}
					foreach (Class cl in ns.get_classes ()) {
						result.classes.add (new SymbolCompletionItem.with_class (cl));
					}
					foreach (Interface cl in ns.get_interfaces ()) {
						result.interfaces.add (new SymbolCompletionItem.with_interface (cl));
					}
					foreach (Struct cl in ns.get_structs ()) {
						result.structs.add (new SymbolCompletionItem.with_struct (cl));
					}
					if (!types_only) {
						foreach (Method cl in ns.get_methods ()) {
							result.methods.add (new SymbolCompletionItem.with_method (cl));
						}
						foreach (Field cl in ns.get_fields ()) {
							result.fields.add (new SymbolCompletionItem.with_field (cl));
						}
						foreach (Constant cl in ns.get_constants ()) {
							result.constants.add (new SymbolCompletionItem (cl.name));
						}
						foreach (Delegate cl in ns.get_delegates ()) {
							result.others.add (new SymbolCompletionItem (cl.name));
						}
						foreach (Enum cl in ns.get_enums ()) {
							result.enums.add (new SymbolCompletionItem (cl.name));
						}
						if (null != kl) {
							foreach (Method cl in kl.get_methods ()) {
								result.methods.add (new SymbolCompletionItem.with_method (cl));
							}
							foreach (Field cl in kl.get_fields ()) {
								result.fields.add (new SymbolCompletionItem.with_field (cl));
							}
							foreach (Constant cl in kl.get_constants ()) {
								result.constants.add (new SymbolCompletionItem (cl.name));
							}
							foreach (Delegate cl in kl.get_delegates ()) {
								result.others.add (new SymbolCompletionItem (cl.name));
							}
							foreach (Enum cl in ns.get_enums ()) {
								result.enums.add (new SymbolCompletionItem (cl.name));
							}
							foreach (Vala.Signal cl in kl.get_signals ()) {
								result.signals.add (new SymbolCompletionItem.with_signal (cl));
							}
						}
					}// Not just types
				}
				
			} finally {
				_parser.unlock_all_contexts ();
			}
			
			return result;
		}
		
		public string get_datatype_name_for_name (string symbolname, string sourcefile, int line, int column) throws SymbolCompletionError
		{
			string typename = null;
			var timer = new Timer ();
			timer.start ();
			var dt = get_datatype_for_name (symbolname, sourcefile, line, column);
			timer.stop ();
			
			if (dt != null) {
				typename = get_qualified_name_for_datatype (dt);
			}
			return typename;
		}
		
		public DataType? get_datatype_for_name (string symbolname, string sourcefile, int line, int column) throws SymbolCompletionError
		{
			warn_if_fail (_parser != null);
			DataType? result = null;
			string[] toks = symbolname.split (".", 2);
			SourceFile source = null;

			_parser.lock_all_contexts ();
			try {
				CodeContext?[] contexts = { _parser.sec_context, _parser.pri_context, null };
				int idx = 0;
				while (contexts[idx] != null) {
					var context = contexts[idx];
					source = find_sourcefile (context, sourcefile);
					if (source != null) {
						//first local
						result = get_datatype_for_name_with_context (context, toks[0], source, line, column);
						if (result != null && toks[1] != null) {
							result = get_inner_datatype (result, toks[1], source);
						}
					} else {
						warning ("(get_datatype_for_name) no sourcefile found %s", sourcefile);
					}
	
					if (result != null) { 
						break;
					}
					idx++;
				}
			} catch (Error err) {
				throw err;
			} finally {
				_parser.unlock_all_contexts ();
			}
			return result;
		}


		private DataType? get_inner_datatype (DataType datatype, string fields_path, SourceFile source) throws SymbolCompletionError
		{
			DataType result = null;
			var finder = new TypeFinderVisitor (source, _parser.pri_context);
			string[] toks = fields_path.split (".", 2);
			string typename = "%s.%s".printf (get_name_for_datatype (datatype), toks[0]); // 
			finder.searched_typename = typename;
			if (datatype is ObjectType) {
				var obj = (ObjectType) datatype;
				obj.type_symbol.accept (finder);
			} else if (datatype is ClassType) {
				var cl = (ClassType) datatype;
				cl.class_symbol.accept (finder);
			} else if (datatype is ValueType) {
				var vl = (ValueType) datatype;
				vl.type_symbol.accept (finder);
			} else {
				datatype.accept (finder);
			}
			
			if (finder.result != null) {
				result = symbol_to_datatype (finder.result);
				if (toks[1] != null) {
					result = get_inner_datatype (result, toks[1], source);
				}
			}
			
			return result;
		}


		private DataType? symbol_to_datatype (Symbol? symbol)
		{
			if (symbol == null)
				return null;
				
			DataType result = null;
			
			if (symbol is Class) {
				result = new ClassType ((Class) symbol);
			} else if (symbol is Field) {
				var field = (Field) symbol;
				result = field.field_type;
			} else if (symbol is Property) {
				var prop = (Property) symbol;
				result = prop.property_type;
			} else if (symbol is Struct) {
				result = new StructValueType ((Struct) symbol);
			} else if (symbol is Method) {
				var method = (Method) symbol;
				result = method.return_type;
			} else {
				warning ("(get_datatype_for_symbol_name): unsupported type %s", Reflection.get_type_from_instance (symbol).name ());
			}
			
			return result;	
		}
		
		private Block? get_codenode_body (CodeNode codenode)
		{
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
			} else if (codenode is CatchClause) {
				body = ((CatchClause) codenode).body;
			} else if (codenode is PropertyAccessor) {
				body = ((PropertyAccessor) codenode).body;
			} else {
				warning ("(get_codenode_body) unsupported type %s", Reflection.get_type_from_instance (codenode).name ());
			}
			return body;					
		}
		
 		private DataType? get_datatype_for_name_in_code_node_with_context (CodeNode codenode, CodeContext context, string symbolname, SourceFile? source, int line, int column) throws SymbolCompletionError
 		{
			if (symbolname != "this" && symbolname != "base") {
				Block body = get_codenode_body (codenode);
				if (body != null) {
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
							if (decl.declaration.name == symbolname) {
								if (decl.declaration is LocalVariable) {
									var type = datatype_for_localvariable (context, source, line, column, (LocalVariable) (decl.declaration));
									if (type != null)
										return type;
								} else {
									warning ("(get_datatype_for_name_with_context) unsupported type %s for %s", Reflection.get_type_from_instance (codenode).name (), symbolname);
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
			}
			if (codenode.parent_node != null) {
				return get_datatype_for_name_in_code_node_with_context (codenode.parent_node, context, symbolname, source, line, column);
			} else {
	 			return null;
 			}
 		}
 		
 		private DataType? get_datatype_for_name_with_context (CodeContext context, string symbolname, SourceFile? source = null, int line = 0, int column = 0) throws SymbolCompletionError
		{
			Class cl = null;
			Method md = null;
			var codenode = find_codenode (source, line, column, out cl, out md);
			if (codenode != null) {
				DataType type = get_datatype_for_name_in_code_node_with_context (codenode, context, symbolname, source, line, column);
				if (type != null)
					return type;
					
				if (cl != null) {
					if (symbolname == "this")
						return new ClassType (cl);
					else if (symbolname == "base") {
						if (cl.base_class != null) {
							return new ClassType (cl.base_class);
						} else {
							foreach (Vala.DataType item in cl.get_base_types ()) {
								if (!(item is Vala.Interface)) {
									//this is a HACK!
									return item;
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
			warn_if_fail (_parser != null);
			DataType vt = null;
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
					
					if (vt == null) {
						string name;
						if (member_name != null && class_name != null) {
							name = "%s.%s".printf (class_name, member_name);
						} else if (class_name != null) {
							name = class_name;
						} else {
							name = member_name;
						}
						
						var finder = new TypeFinderVisitor ();
						finder.searched_typename = name;
						finder.visit_namespace (_parser.pri_context.root);
						vt = symbol_to_datatype(finder.result);
						if (vt == null) {
							foreach (UsingDirective item in source.get_using_directives ()) {
								var using_name = "%s.%s".printf (item.namespace_symbol.name, name);
								finder.searched_typename = using_name;
								finder.visit_namespace (_parser.pri_context.root);
								if (finder.result != null) {
									vt = symbol_to_datatype(finder.result);
									break;
								} 
							}
							if (vt == null) {
								finder = new TypeFinderVisitor (source, _parser.pri_context);
								finder.searched_typename = name;
								finder.visit_namespace (_parser.sec_context.root);
								vt = symbol_to_datatype(finder.result);
							}
						}
					}
				}
			} else if (lv.variable_type != null) {
				vt = lv.variable_type;;
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
			if (typename.has_prefix ("%s.".printf (namespace_name))) {
				return typename;				
			} else {
				return "%s.%s".printf (namespace_name, typename);
			}			
		}

		private string get_qualified_namespace_name (Symbol namespace_symbol)
		{
			string ns_name = null;
			Symbol ns = namespace_symbol;
			while (ns != null && ns.name != null) {
				if (ns_name == null) {
					ns_name = ns.name;
				} else {
					ns_name = "%s.%s".printf (ns.name, ns_name);
				}
				if (ns is UnresolvedSymbol) {
					ns = ((UnresolvedSymbol) ns).inner;
				} else {
					ns = ns.parent_symbol;
				}
			}
			return ns_name;
		}
		
		public SymbolCompletionResult get_completions_for_name (SymbolCompletionFilterOptions options, string symbolname, string? sourcefile = null, int line, int column) throws GLib.Error
		{
			warn_if_fail (_parser != null);
			SymbolCompletionResult result = new SymbolCompletionResult ();
			SourceFile? source = null;
			
			if (sourcefile != null) {
				source = find_sourcefile (_parser.sec_context, sourcefile);
				if (null == source){ source = find_sourcefile (_parser.pri_context, sourcefile); }
			}
			
			//first look in the namespaces defined in the source file
			_parser.lock_all_contexts ();
			if (options.local_variables && source != null) {
				Class cl = null;
				Method md = null;
				var codenode = find_codenode (source, line, column, out cl, out md);
				if (codenode != null) {
					var current = codenode;
					while (current != null) {
						var body = get_codenode_body (current);
						if (body != null) {
							//method local vars
							foreach (LocalVariable lvar in body.get_local_variables ()) {
								result.others.add (new SymbolCompletionItem (lvar.name));
							}
							foreach (Statement st in body.get_statements ()) {
								if (st is DeclarationStatement) {
									var decl = (DeclarationStatement) st;
									result.others.add (new SymbolCompletionItem (decl.declaration.name));
								}
							}

							if (current is ForeachStatement) {
								var fe = (ForeachStatement) current;
								result.others.add (new SymbolCompletionItem (fe.variable_name));
							}
						}
						if (current is Method) {
							//method arguments
							foreach (FormalParameter par in ((Method) current).get_parameters ()) {
								result.others.add (new SymbolCompletionItem (par.name));
							}
							//stop here
							break;
						} else
							current = current.parent_node;
					}
				}
			}
			
			var finder = new TypeFinderVisitor (source,  _parser.pri_context);
			var completion = new CompletionVisitor (options, result, source,  _parser.pri_context);
			if (source != null) {
				foreach (CodeNode node in source.get_nodes ()) {
					if (node is Namespace) {
						var ns = (Namespace) node;
						string ns_name = get_qualified_namespace_name (ns);
						var name = normalize_typename (symbolname, ns_name);
						finder.searched_typename = name;
						finder.visit_namespace (ns);
						if (finder.result != null) {
							finder.result.accept (completion);
							if (finder.result is Namespace) {
								get_completion_for_name_in_namespace_with_context (ns_name, symbolname, 
									finder, completion, _parser.pri_context);
							}
							break;
						} else {
							int tmp = result.count;
							get_completion_for_name_in_namespace_with_context (ns_name, symbolname, 
								finder, completion, _parser.pri_context);
							if (tmp != result.count) {
								break; //found something in primary context
							}
						}
					}
				}					
			} else {
				warning ("no source file found");
			}

			if (finder.result == null) {
				//search it in the root namespace, string and other base types are there
				finder.searched_typename = symbolname;
				finder.visit_namespace (_parser.pri_context.root);
				if (finder.result != null) {
					finder.result.accept (completion);
				}
			}

			//import symbols from the imported namespaces
			if (source != null && options.imported_namespaces) {
				string prev_symbol = finder.searched_typename;
				foreach (UsingDirective item in source.get_using_directives ()) {
					string ns_name = get_qualified_namespace_name (item.namespace_symbol);
					finder.searched_typename = ns_name;
					get_completion_for_name_in_namespace_with_context (ns_name, 
						ns_name, finder, completion, _parser.pri_context);
				}
				finder.searched_typename = prev_symbol;
			}
			
			//search it in referenced namespaces
			if (source != null && finder.result == null && !SymbolCompletion.symbol_has_known_namespace (symbolname)) {
				bool force_exit = false;
				foreach (UsingDirective item in source.get_using_directives ()) {
					int tmp = result.count;
					string ns_name = get_qualified_namespace_name (item.namespace_symbol);
					if (symbolname.has_prefix ("%s.".printf (ns_name)))
						force_exit = true; //exit after this visit since symbolname is surely fully qualified
						
					get_completion_for_name_in_namespace_with_context (ns_name, 
						symbolname, finder, completion, _parser.pri_context);
					if (tmp != result.count || force_exit) {
						break;
					}
				}
			}
			_parser.unlock_all_contexts ();
			return result;
		}
		
		private void get_completion_for_name_in_namespace_with_context (string namespace_name, string typename, TypeFinderVisitor finder, CompletionVisitor completion, CodeContext context)
		{
			string ns_name = namespace_name.split (".", 2)[0];

			foreach (Namespace ns in context.root.get_namespaces ()) {
				if (ns.name == ns_name) {
					bool same_namespace = false;
					if (typename == namespace_name) {
						//search all symbols
						if (namespace_name.str (".") == null) {
							same_namespace = true; //don't waste time finding this exact namespace
						} else {
							finder.searched_typename = namespace_name;							
						}
					} else {
						finder.searched_typename = "%s.%s".printf (namespace_name, typename);
					}
					if (same_namespace) {
						completion.integrate_completion (ns);
					} else {
						finder.visit_namespace (ns);
						if (finder.result != null) {					
							completion.integrate_completion (finder.result);
						}
					}
					break;
				}
			}
		}

		internal static bool symbol_has_known_namespace (string name)
		{
			return (name.has_prefix ("GLib.") || 
				name.has_prefix ("Gtk.") || 
				name.has_prefix ("Gdk."));
		}

	}
}

