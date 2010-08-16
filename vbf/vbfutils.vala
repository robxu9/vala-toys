/*
 *  vbfutils.vala - Vala Build Framework library
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

namespace Vbf.Utils
{
	/**
	 * This function shouldn't be used directly but just wrapped with a private one that
	 * will specify the correct log domain. See the function trace (...) in this same source 
	 */
	internal static inline void log_message (string log_domain, string format, va_list args)
	{
		logv (log_domain, GLib.LogLevelFlags.LEVEL_INFO, format, args);
	}

	[Diagnostics]
	[PrintfFormat]
	internal static inline void trace (string format, ...)
	{
#if DEBUG
		var va = va_list ();
		var va2 = va_list.copy (va);
		log_message ("ValaBuildFramework", format, va2);
#endif
	}

	public bool is_autotools_project (string path)
	{
		string file = Path.build_filename (path, "configure.ac");
		bool res = false;

		if (GLib.FileUtils.test (file, FileTest.EXISTS)) {
			file = Path.build_filename (path, "Makefile.am");
			if (GLib.FileUtils.test (file, FileTest.EXISTS)) {
				res = true;
			}
		}

		return res;
	}

	public bool is_waf_project (string path)
	{
		string file = Path.build_filename (path, "wscript");
		bool res = false;

		if (GLib.FileUtils.test (file, FileTest.EXISTS)) {
			res = true;
		}

		return res;
	}

	public bool is_cmake_project (string path)
	{
		string file = Path.build_filename (path, "CMakeLists.txt");
		bool res = false;

		if (GLib.FileUtils.test (file, FileTest.EXISTS)) {
			res = true;
		}

		return res;
	}

	public bool is_simple_make_project (string path)
	{
		string file = Path.build_filename (path, "Makefile");
		bool res = false;

		if (GLib.FileUtils.test (file, FileTest.EXISTS)) {
			res = true;
		}

		return res;
	}
}
