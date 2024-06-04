#!/bin/bash
# -----------------------------------------------------------------------------
# Purpose: A script to delete installed KDE Plasma packages; either a single
#          package, or a complete module, or all of the packages.
#          Or using the '-n' commandline switch, merely show what would be
#          removed and what's not installed, without actually removing anything.
# Author:  Eric Hameleers <alien@slackware.com>
# Date:    20231030
# -----------------------------------------------------------------------------

# Defaults:

ADM_DIR="/var/lib/pkgtools"
DRYRUN=0
MODS=""

# Find whether a package is actually installed; input is the basename:
findpkg() {
  local PKGNAME="${1}"
  pushd ${ADM_DIR}/packages > /dev/null
    PKGNAME=$( ls -1t |grep -E "${PKGNAME}-[^-]+-[^-]+-[^-]+$" 2>/dev/null |head -n1 )
    echo ${PKGNAME}
  popd > /dev/null
} # End findpkg()

# Show/remove packages and mention those that are not installed:
doremove() {
  local MYPKG
  MYPKG="$(findpkg ${1})"
  if [ -z "$MYPKG" ]; then
    echo "++ Package '${1}' is not installed."
  elif [ ${DRYRUN} -eq 1 ]; then
    echo "++ Package '${1}' is installed and would be removed."
  else
    removepkg ${1}
  fi
} # End doremove()

# Parse the commandline parameters:
while getopts "hn" Option
do
  case $Option in
    n )
      DRYRUN=1
      shift
      ;;
    h|* )
      echo "$(basename $0) [<param>] [<module> [<module[:package[,package]]>] ...]"
      echo "Parameters are:"
      echo "  -n            Show what the script would do, without actually"
      echo "                doing it (dry-run)"
      echo "  -h            This help."
      exit
      ;;
  esac
done

shift $(($OPTIND - 1))
# End of option parsing.
#  $1 now references the first non option item supplied on the command line
#  if one exists.
# -----------------------------------------------------------------------------

# Remaining commandline options are the requested modules/packages to remove:
MODS="${*}"

# Remove Plasma packages from the computer:
cd $(dirname $0) ; CWD=$(pwd)
if [ -n "$MODS" ]; then
  # Remove a specific set of packages (frameworks, plasma, kdepim, ...)
  for THEMOD in $MODS ; do
    for MYPKG in $(cat $CWD/modules/${THEMOD} |sort |uniq |grep -Ev '(^#|^$)') ; do
      doremove ${MYPKG}
    done
  done
else
  for MYPKG in $(cat $CWD/modules/* |sort |uniq |grep -Ev '(^#|^$)') ; do
    doremove ${MYPKG}
  done
fi
# The end!
