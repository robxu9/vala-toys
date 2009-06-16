AC_INIT([vtg], [0.5.0], [sejerpz@tin.it], [vtg])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])
AM_MAINTAINER_MODE

AC_PROG_CC
AM_PROG_CC_C_O
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)

AH_TEMPLATE([GETTEXT_PACKAGE], [Vala toys for GEdit])
GETTEXT_PACKAGE=vtg
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE")
AC_SUBST(GETTEXT_PACKAGE)
AM_GLIB_GNU_GETTEXT
IT_PROG_INTLTOOL([0.35.0])

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

GLIB_REQUIRED=2.12.0
GTHREAD_REQUIRED=2.16.0
GTK_REQUIRED=2.10.0
GEDIT_REQUIRED=2.22.0
GTKSOURCECOMPLETION_REQUIRED=0.7.0
VALA_REQUIRED=0.5.7
GCONF_REQUIRED=2.22.0

AC_ARG_ENABLE(debug, AS_HELP_STRING([--enable-debug], [Enable debug messages]), enable_debug=$enableval, enable_debug=no)
AM_CONDITIONAL(ENABLE_DEBUG, test x$enable_debug = xyes)

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

AC_ARG_ENABLE([vsc-shell],
    AS_HELP_STRING([--disable-vsc-shell],[Disable vsc-shell program]),
        [
            case "${enableval}" in
                yes) vscshell=yes ;;
                no) vscshell=no ;;
                *) AC_MSG_ERROR(bad value ${enableval} for --disable-vsc-shell) ;;
            esac
        ],
        [vscshell=auto])

### gen-project ###############################################
if test "x${genprj}" != xno ; then
	PKG_CHECK_MODULES(GENPROJECT, 
		[glib-2.0 >= $GLIB_REQUIRED gobject-2.0 >= $GLIB_REQUIRED gtk+-2.0 >= $GTK_REQUIRED],
		HAVE_GENPRJ=1,
		[
			HAVE_GENPRJ=0
			AC_MSG_RESULT([gen-project dependencies not met:])
			PKG_CHECK_EXISTS([glib-2.0 >= $GLIB_REQUIRED] ,, AC_MSG_RESULT([    glib-2.0 >= $GLIB_REQUIRED: not found]))
			PKG_CHECK_EXISTS([gobject-2.0 >= $GLIB_REQUIRED] ,, AC_MSG_RESULT([    gobject-2.0 >= $GLIB_REQUIRED: not found]))
			PKG_CHECK_EXISTS([gtk+-2.0 >= $GTK_REQUIRED] ,, AC_MSG_RESULT([    gtk+-2.0 >= $GTK_REQUIRED: not found]))
			if test "x$genprj" = xyes ; then
				AC_MSG_ERROR([gen-project dependencies not met: glib-2.0 >= $GLIB_REQUIRED gobject-2.0 >= $GLIB_REQUIRED gtk+-2.0 >= $GTK_REQUIRED])
			fi
		])
else
    HAVE_GENPRJ=0
fi

AC_SUBST(GENPROJECT_CFLAGS)
AC_SUBST(GENPROJECT_LIBS)
AC_SUBST(HAVE_GENPRJ)
AM_CONDITIONAL([HAVE_GENPRJ], [test "x$HAVE_GENPRJ" = x1])
###############################################################

if test "x${vtgplugin}" != xno -o "x${vscshell}" != xno; then
	PKG_CHECK_MODULES(VSC, 
		[glib-2.0 >= $GLIB_REQUIRED gio-2.0 >= $GLIB_REQUIRED
		gobject-2.0 >= $GLIB_REQUIRED 
		gthread-2.0 >= $GTHREAD_REQUIRED 
		vala-1.0 >= $VALA_REQUIRED],
		HAVE_VSC=1,
		[
			HAVE_VSC=0
			AC_MSG_RESULT([vsc library dependencies not met:])
			PKG_CHECK_EXISTS([glib-2.0 >= $GLIB_REQUIRED] ,, AC_MSG_RESULT([    glib-2.0 >= $GLIB_REQUIRED: not found]))
			PKG_CHECK_EXISTS([gio-2.0 >= $GLIB_REQUIRED] ,, AC_MSG_RESULT([    gio-2.0 >= $GLIB_REQUIRED: not found]))
			PKG_CHECK_EXISTS([gobject-2.0 >= $GLIB_REQUIRED] ,, AC_MSG_RESULT([    gobject-2.0 >= $GLIB_REQUIRED: not found]))
			PKG_CHECK_EXISTS([gthread-2.0 >= $GTHREAD_REQUIRED] ,, AC_MSG_RESULT([    gthread-2.0 >= $GTHREAD_REQUIRED: not found]))
			PKG_CHECK_EXISTS([vala-1.0 >= $VALA_REQUIRED] ,, AC_MSG_RESULT([    vala-1.0 >= $VALA_REQUIRED: not found]))

			if test "x$vscshell" = xyes -o "x$vtgplugin" = xyes; then
				AC_MSG_ERROR([vsc library dependencies not met: glib-2.0 >= $GLIB_REQUIRED gio-2.0 >= $GLIB_REQUIRED gobject-2.0 >= $GLIB_REQUIRED gthread-2.0 >= $GTHREAD_REQUIRED vala-1.0 >= $VALA_REQUIRED])
			fi
		])
else
    HAVE_VSC=0
fi

AC_SUBST(VSC_CFLAGS)
AC_SUBST(VSC_LIBS)
AC_SUBST(HAVE_VSC)
AM_CONDITIONAL([HAVE_VSC], [test "x$HAVE_VSC" = x1])

### vsc-shell #################################################
if test "x${vscshell}" != xno ; then
	PKG_CHECK_MODULES(VSCSHELL, 
		[glib-2.0 >= $GLIB_REQUIRED gio-2.0 >= $GLIB_REQUIRED
		gobject-2.0 >= $GLIB_REQUIRED 
		gthread-2.0 >= $GTHREAD_REQUIRED
		vala-1.0 >= $VALA_REQUIRED],
		HAVE_VSCSHELL=1,
		[
			HAVE_VSCSHELL=0
			AC_MSG_RESULT([vsc-shell dependencies not met:])
			PKG_CHECK_EXISTS([glib-2.0 >= $GLIB_REQUIRED] ,, AC_MSG_RESULT([    glib-2.0 >= $GLIB_REQUIRED: not found]))
			PKG_CHECK_EXISTS([gio-2.0 >= $GLIB_REQUIRED] ,, AC_MSG_RESULT([    gio-2.0 >= $GLIB_REQUIRED: not found]))
			PKG_CHECK_EXISTS([gobject-2.0 >= $GLIB_REQUIRED] ,, AC_MSG_RESULT([    gobject-2.0 >= $GLIB_REQUIRED: not found]))
			PKG_CHECK_EXISTS([gthread-2.0 >= $GTHREAD_REQUIRED] ,, AC_MSG_RESULT([    gthread-2.0 >= $GTHREAD_REQUIRED: not found]))
			PKG_CHECK_EXISTS([vala-1.0 >= $VALA_REQUIRED] ,, AC_MSG_RESULT([    vala-1.0 >= $VALA_REQUIRED: not found]))

			if test "x$vscshell" = xyes ; then
				AC_MSG_ERROR([vsc-shell dependencies not met: glib-2.0 >= $GLIB_REQUIRED gio-2.0 >= $GLIB_REQUIRED gobject-2.0 >= $GLIB_REQUIRED gthread-2.0 >= $GTHREAD_REQUIRED vala-1.0 >= $VALA_REQUIRED])
			fi
		])
	AC_CHECK_LIB(readline,readline,, 
		[
			HAVE_VSCSHELL=0
			AC_MSG_RESULT([cannot find readline library]) 
		])
	AC_CHECK_HEADER([readline/readline.h],, 
		[
			HAVE_VSCSHELL=0
			AC_MSG_RESULT([cannot find readline headers is the readline 'dev' package installed?])
		])
else
    HAVE_VSCSHELL=0
fi

AC_SUBST(VSCSHELL_CFLAGS)
AC_SUBST(VSCSHELL_LIBS)
AC_SUBST(HAVE_VSCSHELL)
AM_CONDITIONAL([HAVE_VSCSHELL], [test "x$HAVE_VSCSHELL" = x1])
################################################################

### vtg-plugin #################################################
if test "x${vtgplugin}" != xno ; then
	PKG_CHECK_MODULES(VTGPLUGIN, 
		[glib-2.0 >= $GLIB_REQUIRED 
		gobject-2.0 >= $GLIB_REQUIRED 
		gthread-2.0 >= $GTHREAD_REQUIRED 
		gtk+-2.0 >= $GTK_REQUIRED 
		gedit-2.20 >= $GEDIT_REQUIRED 
		gtksourcecompletion-2.0 >= $GTKSOURCECOMPLETION_REQUIRED
		vala-1.0 >= $VALA_REQUIRED 
		gconf-2.0 >= $GCONF_REQUIRED],
		HAVE_VTGPLUGIN=1,
		[
			HAVE_VTGPLUGIN=0
			AC_MSG_RESULT([vtg-plugin dependencies not met:])
			PKG_CHECK_EXISTS([glib-2.0 >= $GLIB_REQUIRED] ,, AC_MSG_RESULT([    glib-2.0 >= $GLIB_REQUIRED: not found]))
			PKG_CHECK_EXISTS([gobject-2.0 >= $GLIB_REQUIRED] ,, AC_MSG_RESULT([    gobject-2.0 >= $GLIB_REQUIRED: not found]))
			PKG_CHECK_EXISTS([gthread-2.0 >= $GTHREAD_REQUIRED] ,, AC_MSG_RESULT([    gthread-2.0 >= $GTHREAD_REQUIRED: not found]))
			PKG_CHECK_EXISTS([gtk+-2.0 >= $GTK_REQUIRED] ,, AC_MSG_RESULT([    gtk+-2.0 >= $GTK_REQUIRED: not found]))
			PKG_CHECK_EXISTS([gedit-2.20 >= $GEDIT_REQUIRED] ,, AC_MSG_RESULT([    gedit-2.20 >= $GEDIT_REQUIRED: not found]))
			PKG_CHECK_EXISTS([gtksourcecompletion-2.0 >= $GTKSOURCECOMPLETION_REQUIRED] ,, AC_MSG_RESULT([    gtksourcecompletion-2.0 >= $GTKSOURCECOMPLETION_REQUIRED: not found]))
			PKG_CHECK_EXISTS([vala-1.0 >= $VALA_REQUIRED] ,, AC_MSG_RESULT([    vala-1.0 >= $VALA_REQUIRED: not found]))
			PKG_CHECK_EXISTS([gconf-2.0 >= $GCONF_REQUIRED] ,, AC_MSG_RESULT([    gconf-2.0 >= $GCONF_REQUIRED: not found]))
			if test "x$vtgplugin" = xyes ; then
				AC_MSG_ERROR([vtg-plugin dependencies not met: glib-2.0 >= $GLIB_REQUIRED gio-2.0 >= $GLIB_REQUIRED gobject-2.0 >= $GLIB_REQUIRED gthread-2.0 >= $GTHREAD_REQUIRED vala-1.0 >= $VALA_REQUIRED gtk+-2.0 >= $GTK_REQUIRED gedit-2.20 >= $GEDIT_REQUIRED gtksourcecompletion-2.0 >= $GTKSOURCECOMPLETION_REQUIRED gconf-2.0 >= GCONF_REQUIRED])
			fi
		])
else
    HAVE_VTGPLUGIN=0
fi

AC_SUBST(VTGPLUGIN_CFLAGS)
AC_SUBST(VTGPLUGIN_LIBS)
AC_SUBST(HAVE_VTGPLUGIN)
AM_CONDITIONAL([HAVE_VTGPLUGIN], [test "x$HAVE_VTGPLUGIN" = x1])
##########################################################

AC_CONFIG_FILES([
	Makefile
	vsc/Makefile
	vsc-shell/Makefile
	gen-project/Makefile
	gen-project/licenses/Makefile
	doc/Makefile
	vtg/Makefile
	vbf/Makefile
	ui/Makefile
	images/Makefile
	po/Makefile.in])

AC_OUTPUT

##########################################################
ENABLE_GENPRJ=no
if test "x$HAVE_GENPRJ" = "x1" ; then
   ENABLE_GENPRJ=yes
fi

ENABLE_VSC=no
if test "x$HAVE_VSC" = "x1" ; then
   ENABLE_VSC=yes
fi

ENABLE_VSCSHELL=no
if test "x$HAVE_VSCSHELL" = "x1" ; then
   ENABLE_VSCSHELL=yes
fi

ENABLE_VTGPLUGIN=no
if test "x$HAVE_VTGPLUGIN" = "x1" ; then
   ENABLE_VTGPLUGIN=yes
fi

echo "
 ---{ $PACKAGE_NAME $VERSION }---

    prefix:                        ${prefix}
    sysconfdir:                    ${sysconfdir}
    localstatedir:                 ${localstatedir}
    C Compiler:                    ${CC}
    CFLAGS:                        ${CFLAGS}
    Enable gen-project:            ${ENABLE_GENPRJ}
    Enable vsc library:            ${ENABLE_VSC}
    Enable vtg:                    ${ENABLE_VTGPLUGIN}
    Enable vsc-shell:              ${ENABLE_VSCSHELL}
"

