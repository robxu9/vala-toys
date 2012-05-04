AC_INIT([vtg], m4_esyscmd([build-aux/git-version-gen .tarball-version]), [sejerpz@tin.it], [vtg])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])
AM_MAINTAINER_MODE

AC_CONFIG_MACRO_DIR([m4])

AC_PROG_CC
AM_PROG_CC_C_O
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)

GLIB_GSETTINGS

AH_TEMPLATE([GETTEXT_PACKAGE], [Vala toys for GEdit])
GETTEXT_PACKAGE=vtg
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE")
AC_SUBST(GETTEXT_PACKAGE)
AM_GLIB_GNU_GETTEXT
IT_PROG_INTLTOOL([0.35.0])

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

GLIB_REQUIRED=2.28.0
GTHREAD_REQUIRED=2.28.0
GTK_REQUIRED=3.0.0
GEDIT_REQUIRED=3.0.0
GTKSOURCEVIEW_REQUIRED=3.0.0
VALA_REQUIRED=0.16.0
VALA_VERSION=0.16
PEAS_REQUIRED=0.7.4
AFRODITE_REQUIRED=

PACKAGE_SUFFIX=-0.16
AC_SUBST(PACKAGE_SUFFIX)
AC_DEFINE_UNQUOTED(PACKAGE_SUFFIX, "$PACKAGE_SUFFIX", [Define the suffix of this package])



AC_ARG_ENABLE(debug, AS_HELP_STRING([--enable-debug], [Enable debug messages]), enable_debug=$enableval, enable_debug=no)
AM_CONDITIONAL(ENABLE_DEBUG, test x$enable_debug = xyes)


AC_ARG_WITH([systemlibs], AS_HELP_STRING([--with-systemlibs], [Use the system wide installed copy of libraries [default=no]]), 
 	[
            case "${withval}" in
                yes) systemlibs=yes ;;
                no) systemlibs=no ;;
                *) AC_MSG_ERROR(bad value ${withval} for --with-systemlibs) ;;
            esac
        ],
	[systemlibs=no])
AM_CONDITIONAL(WITH_SYSTEMLIBS, test x$systemlibs = xyes)


### directory of standard vapis distributed with the vala compiler ###
AC_ARG_WITH([vapidir], AS_HELP_STRING([--with-vapidir=PATH],[use PATH for default vala vapi directory]), [
	        VALA_VAPIDIR=$withval
	],[
		#standard vala installation
	        VALA_VAPIDIR=$(pkg-config --variable=vapidir libvala-$VALA_VERSION)
	])

AC_DEFINE_UNQUOTED([VALA_VAPIDIR], ["$VALA_VAPIDIR"], [Vala vapi directory])

### directory for vapis from 3rd party library not included in standard vala distribution ###
VAPIDIR=`echo ${datadir}/vala/vapi`
AC_SUBST(VAPIDIR)

### gen-project ####

AC_ARG_ENABLE([gen-project],
    AS_HELP_STRING([--disable-gen-project],[Disable vala gen-project program]),
        [
            case "${enableval}" in
                yes) genprj=yes ;;
                no) genprj=no ;;
                *) AC_MSG_ERROR(bad value ${enableval} for --disable-gen-project) ;;
            esac
        ],
        [genprj=yes])

AC_ARG_ENABLE([afrodite],
    AS_HELP_STRING([--disable-afrodite],[Disable vala afrodite library]),
        [
            case "${enableval}" in
                yes) afrodite=yes ;;
                no) afrodite=no ;;
                *) AC_MSG_ERROR(bad value ${enableval} for --disable-afrodite) ;;
            esac
        ],
        [afrodite=yes])

AC_ARG_ENABLE([vtg-plugin],
    AS_HELP_STRING([--disable-vtg-plugin],[Disable vtg gEdit plugin]),
        [
            case "${enableval}" in
                yes) vtgplugin=yes ;;
                no) vtgplugin=no ;;
                *) AC_MSG_ERROR(bad value ${enableval} for --disable-vtg-plugin) ;;
            esac
        ],
        [vtgplugin=yes])

AC_SUBST(VALA_VERSION)
AC_DEFINE_UNQUOTED([VALA_VERSION], ["$VALA_VERSION"], [Vala vapi directory version suffix])


# dummy check to initialize pkg-config. Is this a PKG_CHECK_MODULES bug?
PKG_CHECK_MODULES(GLIB, [glib-2.0 >= $GLIB_REQUIRED],,)

### gen-project ###############################################
if test "x${genprj}" != xno ; then
	AC_CHECK_LIBM
	PKG_CHECK_MODULES(GENPROJECT, 
		[glib-2.0 >= $GLIB_REQUIRED gobject-2.0 >= $GLIB_REQUIRED gtk+-3.0 >= $GTK_REQUIRED],
		HAVE_GENPROJECT=1,
		[
			HAVE_GENPROJECT=0
			AC_MSG_RESULT([gen-project dependencies not met:])
			PKG_CHECK_EXISTS([glib-2.0 >= $GLIB_REQUIRED] ,, AC_MSG_RESULT([    glib-2.0 >= $GLIB_REQUIRED: not found]))
			PKG_CHECK_EXISTS([gobject-2.0 >= $GLIB_REQUIRED] ,, AC_MSG_RESULT([    gobject-2.0 >= $GLIB_REQUIRED: not found]))
			PKG_CHECK_EXISTS([gtk+-3.0 >= $GTK_REQUIRED] ,, AC_MSG_RESULT([    gtk+-3.0 >= $GTK_REQUIRED: not found]))
			if test "x$genprj" = xyes ; then
				AC_MSG_ERROR([gen-project dependencies not met: please install the required packages and run configure again])
			fi
		])
else
    HAVE_GENPROJECT=0
fi

AC_SUBST(GENPROJECT_CFLAGS)
AC_SUBST(GENPROJECT_LIBS)
AC_SUBST(HAVE_GENPROJECT)
AC_SUBST(LIBM)
AM_CONDITIONAL([HAVE_GENPROJECT], [test "x$HAVE_GENPROJECT" = x1])

###############################################################
if test "x${afrodite}" != xno ; then
	PKG_CHECK_MODULES(AFRODITE, 
		[glib-2.0 >= $GLIB_REQUIRED gio-2.0 >= $GLIB_REQUIRED gobject-2.0 >= $GLIB_REQUIRED gthread-2.0 >= $GTHREAD_REQUIRED libvala-$VALA_VERSION >= $VALA_REQUIRED],
		HAVE_AFRODITE=1,
		[
			HAVE_AFRODITE=0
			AC_MSG_RESULT([afrodite library dependencies not met:])
			PKG_CHECK_EXISTS([glib-2.0 >= $GLIB_REQUIRED] ,, AC_MSG_RESULT([    glib-2.0 >= $GLIB_REQUIRED: not found]))
			PKG_CHECK_EXISTS([gio-2.0 >= $GLIB_REQUIRED] ,, AC_MSG_RESULT([    gio-2.0 >= $GLIB_REQUIRED: not found]))
			PKG_CHECK_EXISTS([gobject-2.0 >= $GLIB_REQUIRED] ,, AC_MSG_RESULT([    gobject-2.0 >= $GLIB_REQUIRED: not found]))
			PKG_CHECK_EXISTS([gthread-2.0 >= $GTHREAD_REQUIRED] ,, AC_MSG_RESULT([    gthread-2.0 >= $GTHREAD_REQUIRED: not found]))
			PKG_CHECK_EXISTS([libvala-$VALA_VERSION >= $VALA_REQUIRED] ,, AC_MSG_RESULT([    libvala-$VALA_VERSION >= $VALA_REQUIRED: not found]))

			if test "x$afrodite" = xyes ; then
				AC_MSG_ERROR([afrodite library dependencies not met: please install the required packages and run configure again])
			fi
		])
else
	HAVE_AFRODITE=0
	if test "x${vtgplugin}" != xno ; then
		if test "x${with_systemlibs}" != xyes ; then
			AC_MSG_ERROR([afrodite library was disabled from configure command line, but vtg plugin requires it. Please disable vtg plugin too, reenable afrodite or use the with-systemlibs configure switch.])
		fi
	fi 
fi

AC_SUBST(AFRODITE_CFLAGS)
AC_SUBST(AFRODITE_LIBS)
AC_SUBST(HAVE_AFRODITE)
AM_CONDITIONAL([HAVE_AFRODITE], [test "x$HAVE_AFRODITE" = x1])

### vtg-plugin #################################################
if test "x${vtgplugin}" != xno ; then

	if test "x$systemlibs" = xyes ; then
		CHECK_SYSTEM_AFRODITE=libafrodite$PACKAGE_SUFFIX >= $AFRODITE_REQUIRED
	else
		CHECK_SYSTEM_AFRODITE=
	fi

	PKG_CHECK_MODULES(VBF, 
		[glib-2.0 >= $GLIB_REQUIRED gio-2.0 >= $GLIB_REQUIRED gobject-2.0 >= $GLIB_REQUIRED gthread-2.0 >= $GTHREAD_REQUIRED libvala-$VALA_VERSION >= $VALA_REQUIRED],
		HAVE_VTGPLUGIN=1,
		[
			HAVE_VTGPLUGIN=0
			AC_MSG_RESULT([vbf utility library dependencies not met:])
			PKG_CHECK_EXISTS([glib-2.0 >= $GLIB_REQUIRED] ,, AC_MSG_RESULT([    glib-2.0 >= $GLIB_REQUIRED: not found]))
			PKG_CHECK_EXISTS([gio-2.0 >= $GLIB_REQUIRED] ,, AC_MSG_RESULT([    gio-2.0 >= $GLIB_REQUIRED: not found]))
			PKG_CHECK_EXISTS([gobject-2.0 >= $GLIB_REQUIRED] ,, AC_MSG_RESULT([    gobject-2.0 >= $GLIB_REQUIRED: not found]))
			PKG_CHECK_EXISTS([gthread-2.0 >= $GTHREAD_REQUIRED] ,, AC_MSG_RESULT([    gthread-2.0 >= $GTHREAD_REQUIRED: not found]))
			PKG_CHECK_EXISTS([libvala-$VALA_VERSION >= $VALA_REQUIRED] ,, AC_MSG_RESULT([    libvala-$VALA_VERSION >= $VALA_REQUIRED: not found]))

			if test "x$vtgplugin" = xyes ; then
				AC_MSG_ERROR([vbf utility library dependencies not met: please install the required packages and run configure again])
			fi
		])

	if test "x$HAVE_VTGPLUGIN" = x1 ; then
		PKG_CHECK_MODULES(VTGPLUGIN, 
			[glib-2.0 >= $GLIB_REQUIRED 
			gobject-2.0 >= $GLIB_REQUIRED 
			gthread-2.0 >= $GTHREAD_REQUIRED 
			gtk+-3.0 >= $GTK_REQUIRED 
			gtksourceview-3.0 >= $GTKSOURCEVIEW_REQUIRED 
			gedit >= $GEDIT_REQUIRED 
			libvala-$VALA_VERSION >= $VALA_REQUIRED 
			libpeas-1.0 >= $PEAS_REQUIRED
			libpeas-gtk-1.0 >= $PEAS_REQUIRED
			$CHECK_SYSTEM_AFRODITE	
			],
			HAVE_VTGPLUGIN=1,
			[
				HAVE_VTGPLUGIN=0
				AC_MSG_RESULT([vtg-plugin dependencies not met:])
				PKG_CHECK_EXISTS([glib-2.0 >= $GLIB_REQUIRED] ,, AC_MSG_RESULT([    glib-2.0 >= $GLIB_REQUIRED: not found]))
				PKG_CHECK_EXISTS([gobject-2.0 >= $GLIB_REQUIRED] ,, AC_MSG_RESULT([    gobject-2.0 >= $GLIB_REQUIRED: not found]))
				PKG_CHECK_EXISTS([gthread-2.0 >= $GTHREAD_REQUIRED] ,, AC_MSG_RESULT([    gthread-2.0 >= $GTHREAD_REQUIRED: not found]))
				PKG_CHECK_EXISTS([gtk+-3.0 >= $GTK_REQUIRED] ,, AC_MSG_RESULT([    gtk+-3.0 >= $GTK_REQUIRED: not found]))
				PKG_CHECK_EXISTS([gedit >= $GEDIT_REQUIRED] ,, AC_MSG_RESULT([    gedit >= $GEDIT_REQUIRED: not found]))
				PKG_CHECK_EXISTS([gtksourceview-3.0 >= $GTKSOURCEVIEW_REQUIRED] ,, AC_MSG_RESULT([    gtksourceview-3.0 >= $GTKSOURCEVIEW_REQUIRED: not found]))
				PKG_CHECK_EXISTS([libvala-$VALA_VERSION >= $VALA_REQUIRED] ,, AC_MSG_RESULT([    libvala-$VALA_VERSION >= $VALA_REQUIRED: not found]))
				PKG_CHECK_EXISTS([libpeas-1.0 >= $PEAS_REQUIRED] ,, AC_MSG_RESULT([    libpeas-1.0 >= $PEAS_REQUIRED: not found]))
				PKG_CHECK_EXISTS([libpeas-gtk-1.0 >= $PEAS_REQUIRED] ,, AC_MSG_RESULT([    libpeas-1.0 >= $PEAS_REQUIRED: not found]))
				if test "x$systemlibs" = xyes ; then
					PKG_CHECK_EXISTS([$CHECK_SYSTEM_AFRODITE] ,, AC_MSG_RESULT([    libafrodite$PACKAGE_SUFFIX: not found]))
				fi
				if test "x$vtgplugin" = xyes ; then
					AC_MSG_ERROR([vtg-plugin dependencies not met: please install the required packages and run configure again])
				fi
			])
	fi
else
    HAVE_VTGPLUGIN=0
fi

AC_SUBST(VBF_CFLAGS)
AC_SUBST(VBF_LIBS)
AC_SUBST(VTGPLUGIN_CFLAGS)
AC_SUBST(VTGPLUGIN_LIBS)
AC_SUBST(HAVE_VTGPLUGIN)
AM_CONDITIONAL([HAVE_VTGPLUGIN], [test "x$HAVE_VTGPLUGIN" = x1])
##########################################################

m4_ifdef([AM_SILENT_RULES],[AM_SILENT_RULES([yes])])

AC_CONFIG_FILES([
	Makefile
	afrodite/Makefile
	afrodite/libafrodite.pc
	afrodite/tests/Makefile
	gen-project/libgen-project/Makefile
	gen-project/ui/Makefile
	gen-project/Makefile
	gen-project/licenses/Makefile
	gen-project/templates/Makefile
	doc/Makefile
	vtg/Makefile
	vapi/Makefile
	vbf/Makefile
	ui/Makefile
	images/Makefile
	data/Makefile
	data/org.gnome.gedit.plugins.vala-toys.gschema.xml.in
	po/Makefile.in])

AC_OUTPUT

##########################################################
ENABLE_GENPROJECT=no
if test "x$HAVE_GENPROJECT" = "x1" ; then
   ENABLE_GENPROJECT=yes
fi

ENABLE_AFRODITE=no
if test "x$HAVE_AFRODITE" = "x1" ; then
   ENABLE_AFRODITE=yes
fi

ENABLE_VTGPLUGIN=no
if test "x$HAVE_VTGPLUGIN" = "x1" ; then
   ENABLE_VTGPLUGIN=yes
fi

USE_SYSTEMLIBS=no
if test "x$systemlibs" = "xyes" ; then
   USE_SYSTEMLIBS=yes
fi

echo "
 ---{ $PACKAGE_NAME $VERSION }---

    prefix:                        ${prefix}
    sysconfdir:                    ${sysconfdir}
    localstatedir:                 ${localstatedir}
    C Compiler:                    ${CC}
    CFLAGS:                        ${CFLAGS}
    Vala Vapidir:                  ${VALA_VAPIDIR}
    Enable gen-project:            ${ENABLE_GENPROJECT}
    Enable afrodite library:       ${ENABLE_AFRODITE}
    Use system libraries:          ${USE_SYSTEMLIBS}
    Enable vtg:                    ${ENABLE_VTGPLUGIN}
"

