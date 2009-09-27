/*
 *  vscsourceoutlinervisitor.vala - Vala symbol completion library
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
using Gee;
using Vala;

/**
 * Code visitor a tree structure of SimbolCompletionItem
 */
public class Vsc.SourceOutlinerVisitor : CodeVisitor {
	private Gee.List<SymbolItem> _results = null;
	private SymbolItem _current = null;
	private SourceFile _file = null;
	
	public Gee.List<SymbolItem?> results
	{
		get {
			return _results;
		}
	}
	
	public SourceOutlinerVisitor ()
	{
	}
	
	private SymbolItem add_symbol (Symbol? symbol)
	{
		SymbolItem res;
		
		if (symbol.source_reference.file.filename == _file.filename) {
			res = new SymbolItem (symbol, _current);
			if (_results == null) {
				_results = new Gee.ArrayList<SymbolItem?> ();
			}
			
			if (_current == null) {
				_results.add (res);
			} else {
				_current.add_child (res);
			}
		} else {
			res = _current; // ignore the symbol if defined in another source file
		}
		return res;
	}
	
	public override void visit_source_file (SourceFile file) {
		this._file = file;
		Gee.List<CodeNode> visited_nodes = new Gee.ArrayList<CodeNode> ();
		
		// just visit the top namespaces
		foreach (CodeNode node in file.get_nodes ()) {
			if (node is Namespace) {
				var ns = (Namespace) node;
				
				while (ns.parent_symbol is Namespace
				    && ns.parent_symbol.source_reference.file.filename == _file.filename) {
				    	ns = (Namespace) ns.parent_symbol;
				}
				if (!visited_nodes.contains (ns)) {
					visited_nodes.add (ns);
					ns.accept (this);
				}
			}
		}
	}

	public override void visit_using_directive (UsingDirective ns) 
	{
		//skip using directives
	}
	
	public override void visit_namespace (Namespace ns) 
	{
		var old_current = _current;
		
		_current = add_symbol (ns);
		ns.accept_children (this);
		_current = old_current;
        }
        
       	public override void visit_class (Class cl) 
	{
		var old_current = _current;
		_current = add_symbol (cl);
		
		if (_current.symbol != cl)
			return; // not interesting
			
		foreach (DataType type in cl.get_base_types ()) {
			if (type is Vala.ObjectType) {
				var obj = (ObjectType) type;
				obj.type_symbol.accept (this);
			} else {
				type.accept (this);
			}
		}
		
		foreach (TypeParameter p in cl.get_type_parameters ()) {
			p.accept (this);
		}

		/* process enums first to avoid order problems in C code */
		foreach (Enum en in cl.get_enums ()) {
			en.accept (this);
		}

		foreach (Field f in cl.get_fields ()) {
			f.accept (this);
		}
	
		foreach (Constant c in cl.get_constants()) {
			c.accept (this);
		}
	
		foreach (Method m in cl.get_methods()) {
			m.accept (this);
		}
		foreach (Property prop in cl.get_properties()) {
			prop.accept (this);
		}
	
		foreach (Vala.Signal sig in cl.get_signals()) {
			sig.accept (this);
		}
	
		foreach (Class subcl in cl.get_classes()) {
			subcl.accept (this);
		}
	
		foreach (Struct st in cl.get_structs()) {
			st.accept (this);
		}

		foreach (Delegate d in cl.get_delegates()) {
			d.accept (this);
		}
		
		_current = old_current;
	}

       	public override void visit_interface (Interface iface) 
	{
		var old_current = _current;
		
		_current = add_symbol (iface);
		if (_current.symbol != iface)
			return; // not interesting
					
		foreach (DataType type in iface.get_prerequisites ()) {
			if (type.data_type != null) {
				type.data_type.accept (this);	
			} else {
				type.accept (this);
			}
		}
		
		foreach (TypeParameter p in iface.get_type_parameters ()) {
			p.accept (this);
		}

		/* process enums first to avoid order problems in C code */
		foreach (Enum en in iface.get_enums ()) {
			en.accept (this);
		}

		foreach (Field f in iface.get_fields ()) {
			f.accept (this);
		}
	
		foreach (Method m in iface.get_methods()) {
			m.accept (this);
		}
	
		foreach (Property prop in iface.get_properties()) {
			prop.accept (this);
		}
	
		foreach (Vala.Signal sig in iface.get_signals()) {
			sig.accept (this);
		}
	
		foreach (Class cl in iface.get_classes()) {
			cl.accept (this);
		}
	
		foreach (Struct st in iface.get_structs()) {
			st.accept (this);
		}

		foreach (Delegate d in iface.get_delegates()) {
			d.accept (this);
		}
		
		_current = old_current;
	}
	
       	public override void visit_struct (Struct st) 
	{
		var old_current = _current;
		
		_current = add_symbol (st);
		if (_current.symbol != st)
			return; // not interesting
					
		if (st.base_type != null) {
			st.base_type.accept (this);
		}
		foreach (TypeParameter p in st.get_type_parameters()) {
			p.accept (this);
		}
	
		foreach (Field f in st.get_fields()) {
			f.accept (this);
		}
	
		foreach (Constant c in st.get_constants()) {
			c.accept (this);
		}
	
		foreach (Method m in st.get_methods()) {
			m.accept (this);
		}
		
		_current = old_current;		
	}
	
	public override void visit_enum (Enum en) 
	{
		add_symbol (en);
	}


       	public override void visit_method (Method m) 
	{
		add_symbol (m);
	}

	public override void visit_creation_method (Vala.CreationMethod m)
	{
		add_symbol (m);		
	}

       	public override void visit_delegate (Delegate d) 
	{
		add_symbol (d);
	}

       	public override void visit_signal (Vala.Signal s) 
	{
		add_symbol (s);
	}

       	public override void visit_field (Field f) 
	{
		add_symbol (f);
	}

       	public override void visit_constant (Vala.Constant c) 
	{
		add_symbol (c);
	}
	
       	public override void visit_property (Property p) 
	{
		add_symbol (p);
	}
	
	public override void visit_error_domain (ErrorDomain ed)
	{
		add_symbol (ed);
	}
}

