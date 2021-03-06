/*
 *  vbfiprojectbackend.vala - Vala Build Framework library
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


namespace Vbf
{
	public static bool probe (string path, out IProjectBackend backend)
	{
		IProjectBackend pb = new Backends.Autotools ();
		bool res = pb.probe (path);
		if (!res) {
			pb = new Backends.SmartFolder ();
			res = pb.probe (path);
		}

		if (res) {
			backend = pb;
		} else {
			backend = null;
		}
		return res;
	}

	public interface IProjectBackend : GLib.Object
	{
		public abstract bool probe (string project_file);
		public abstract Project? open (string project_file);
		public abstract void refresh (Project project);
		public abstract string? configure_command {
			owned get;
		}
		public abstract string? build_command {
			owned get;
		}
		public abstract string? clean_command {
			owned get;
		}
	}
}
