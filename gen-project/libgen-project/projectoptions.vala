/* projectoptions.vala
 *
 * Copyright (C) 2007-2010  Jürg Billeter
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Jürg Billeter <j@bitron.ch>
 * 	Andrea Del Signore <sejerpz@tin.it>
 * 	Nicolas Joseph <nicolas.joseph@valaide.org>
 */

using GLib;

namespace GenProject
{
	public class ProjectOptions 
	{
		public TemplateDefinition template;
		public string? path;
		public bool version;
		public string? author;
		public string? email;
		public string? name;
		public string[] files;
		//public GenProject.ProjectType type;
		public GenProject.ProjectLicense license;
		
		public ProjectOptions () 
		{
			//this.type = ProjectType.GTK_APPLICATION;
			this.license = ProjectLicense.LGPL2;
			this.author = Environment.get_variable ("REAL_NAME");
			this.email = Environment.get_variable ("EMAIL_ADDRESS");
		}
	}
}

