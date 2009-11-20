/*
 *  vscclasslistvisitor.vala - Vala symbol completion library
 *  
 *  Copyright (C) 2009 - Levi Bard <taktaktaktaktaktaktaktaktaktak@gmail.com>
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
using Vala;

/**
 * Code visitor getting a list of classes for a source file
 */
public class Vsc.ClassList : CodeVisitor {
	private Vala.List<SymbolCompletionItem> _classes;
	
	public ClassList (Vala.List<SymbolCompletionItem> classes)
	{
		_classes = classes;
	}
	
	public override void visit_source_file (SourceFile file) {
		file.accept_children (this);
	}
	
	public override void visit_namespace (Namespace ns) 
	{
		foreach (Namespace item in ns.get_namespaces()) {
			item.accept (this);
		}
		foreach (Class cl in ns.get_classes ()) {
			cl.accept_children (this);
		}                
		foreach (Struct item in ns.get_structs ()) {
			item.accept_children (this);
		}    
		foreach (Interface item in ns.get_interfaces ()) {
			item.accept_children (this);
		}    
	}
        
	public override void visit_class (Class cl) 
	{
		foreach (Class item in cl.get_classes ()) {
			item.accept_children (this);
		}    
		foreach (Struct item in cl.get_structs ()) {
			item.accept_children (this);
		}    
		_classes.add (new SymbolCompletionItem.with_class (cl));
	}
        
	public override void visit_struct (Struct st) 
	{
		_classes.add (new SymbolCompletionItem.with_struct (st));
	}
        
	public override void visit_interface (Interface cl) 
	{
		_classes.add (new SymbolCompletionItem.with_interface (cl));
	}
}

