/*
 *  vscmethodlistvisitor.vala - Vala symbol completion library
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
using Gee;
using Vala;

/**
 * Code visitor getting a list of methods for a source file
 */
public class Vsc.MethodList : CodeVisitor {
	private Gee.List<SymbolCompletionItem> _methods;
	
	public MethodList (Gee.List<SymbolCompletionItem> methods)
	{
		_methods = methods;
	}
	
        public override void visit_source_file (SourceFile file) {
                file.accept_children (this);
	}
	
	public override void visit_namespace (Namespace ns) 
	{
                foreach (Namespace item in ns.get_namespaces()) {
                        item.accept (this);
                }		
                foreach (Method m in ns.get_methods ()) {
                        m.accept (this);
                }
                foreach (Class cl in ns.get_classes ()) {
                        cl.accept_children (this);
                }                
        }
        
       	public override void visit_class (Class cl) 
	{
		foreach (Class item in cl.get_classes()) {
			item.accept_children (this);
                }    
	}
	
       	public override void visit_method (Method m) 
	{
		_methods.add (new SymbolCompletionItem.with_method(m));
	}
}

