/*
 *  vtgvcsbackendsivcs.vala - Vala developer toys for GEdit
 *  
 *  Copyright (C) 2008 - Andrea Del Signore <sejerpz@tin.it>
 *  
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *   
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *   
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330,
 *  Boston, MA 02111-1307, USA.
 */


using GLib;
using Vala;

namespace Vtg.Vcs.Backends
{
	public enum States
	{
		UNTRACKED,
		ADDED,
		MODIFIED
	}
	
	public class Item
	{
		public string name = "";
		public States state = States.UNTRACKED;
	}
	
	public errordomain VcsError
	{
		CommandFailed
	}
	
	public interface IVcs : GLib.Object
	{
		public abstract Vala.List<Item> get_items (string path) throws GLib.Error;
		public abstract bool test (string path);
	}
}
