#!/bin/sh
# Run this to generate all the initial makefiles, etc.

srcdir=`dirname $0`
test -z "$srcdir" && srcdir=.

PKG_NAME="vtg"

test -z "$VALAC" && VALAC=valac
if ! $VALAC --version | sed -e 's/^.*\([0-9]\+\.[0-9]\+\.[0-9]\+\).*$/\1/' | grep -vq '^0\.[0-9]\.[0-4]'
then
    echo "**Error**: You must have valac >= 0.9.5 installed"
    echo "  to build Vala Toys. Download the appropriate package"
    echo "  from your distribution or get the source tarball at"
    echo "  http://download.gnome.org/sources/vala/"
    exit 1
fi

# Automake requires that ChangeLog exist.
touch ChangeLog
. gnome-autogen.sh
