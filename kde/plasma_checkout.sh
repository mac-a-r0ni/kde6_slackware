#!/bin/bash
# -----------------------------------------------------------------------------
# Purpose: A script to checkout sources for KDE Plasma from the
#          git repositories and create tarballs of them.
# Author:  Eric Hameleers <alien@slackware.com>
# Date:    20231030
# -----------------------------------------------------------------------------

# Defaults:

# Directory where we start:
CWD=$(pwd)

# Cleanup (delete) the directories containing the local clones afterwards:
CLEANUP="NO"
 
# Checkout at a custom date instead of today:
CUSTDATE="NO"

# Forced overwriting of existing tarballs:
FORCE="NO"

# Where to write the files by default:
MYDIR="${CWD}/_plasma_checkouts"

# KDE git repositories:
#KDEGITURI="https://invent.kde.org/"
KDEGITURI="https://github.com/KDE/"

# Default list of modules to checkout:
DEFMODS="frameworks kdepim plasma plasma-extra applications applications-extra"

# Prefered branch to check out from if it exists (HEAD otherwise):
DEFBRANCH="master"

# Shrink the tarball by removing git repository metadata:
SHRINK="YES"

# Today's timestamp:
THEDATE=$(date +%Y%m%d)

# The KDE topdirectory (by default the location of this script):
TOPDIR=$(cd $(dirname $0); pwd)

# Associative array to capture tarball -> source name transformations:
declare -A PKGSRC=(
  [kirigami2]="kirigami"
)

# Tarballs we get from elsewhere because they are not part of KDE, or else
# if we need a specific branch:
declare -A NONSTD=(
  [digikam]="https://invent.kde.org/graphics/#"
  [dolphin]="#kf6"
  [dolphin-plugins]="#kf6"
  [kirigami-gallery]="#kf6"
  [konqueror]="#kf6"
  [konversation]="#port_qt6_keep_konsole"
  [sddm]="https://github.com/sddm/#develop"
)

# Tarballs we ignore (stable versions downloaded separately):
IGNORE=(
  "libkgapi-5"
  "oxygen-gtk2"
  "xwaylandvideobridge"
)

# -----------------------------------------------------------------------------
while getopts "cd:fghk:o:" Option
do
  case $Option in
    c ) CLEANUP="YES"
        ;;
    d ) THEDATE="date --date='${OPTARG}' +%Y%m%d"
        CUSTDATE="${OPTARG}"
        ;;
    f ) FORCE="YES"
        ;;
    g ) SHRINK="NO"
        ;;
    k ) TOPDIR="${OPTARG}"
        ;;
    o ) MYDIR="$(cd ${OPTARG} ; pwd)"
        ;;
    h|* ) 
        echo "$(basename $0) [<param> <param> ...] [<module> <module> ...]"
        echo "Parameters are:"
        echo "  -c            Cleanup afterwards (delete the cloned repos)."
        echo "  -d <date>     Checkout git at <date> instead of today."
        echo "  -f            Force overwriting of tarballs if they exist."
        echo "  -h            This help."
        echo "  -g            Keep git repository metadata (bigger tarball)."
        echo "  -k <dir>      Location of KDE sources if not $(cd $(dirname $0); pwd)/."
        echo "  -o <dir>      Create tarballs in <dir> instead of $MYDIR/."
        exit
        ;;
  esac
done

shift $(($OPTIND - 1))
# End of option parsing.
#  $1 now references the first non option item supplied on the command line
#  if one exists.
# -----------------------------------------------------------------------------

# Catch any individual requests on the commandline,
# like 'frameworks:kactivities,baloo plasma:kwin':
MODS=${1:-"${DEFMODS}"}

# Verify that our TOPDIR is the KDE source top directory:
if ! [ -f ${TOPDIR}/kde.SlackBuild -a -d ${TOPDIR}/src ]; then
  echo ">> Error: '$TOPDIR' does not seem to contain the KDE SlackBuild plus sources"
  echo ">> Either place this script in the KDE directory before running it,"
  echo ">> Or specify the KDE toplevel source directory with the '-k' parameter"
  exit 1
fi

# Create the work directory:
mkdir -p "${MYDIR}"
if [ $? -ne 0 ]; then
  echo "Error creating '${MYDIR}' - aborting."
  exit 1
fi
cd "${MYDIR}"

# Proceed with checking out the sources.
echo ">> Checking out the sources..."
for SRCSET in $MODS ; do
  SET=$(echo $SRCSET | cut -d: -f1)                 # The module name
  SRC="$(echo $SRCSET | cut -d: -f2- |tr ',' ' ')" # Optional package list
  if [ "$SET" == "$SRC" ]; then
    # No package names were supplied so we fetch all of them:
    SRC="$(cat ${TOPDIR}/modules/${SET} | grep -v " *#" | grep -v "^$")"
  fi
  mkdir -p ${SET} 
  echo ">>   Module ${SET}..."
  for LOC in $SRC ; do
    # Should we ignore it?
    if [[ " ${IGNORE} " =~ " ${LOC} " ]]; then
      echo ">>     Ignoring ${SET}:${LOC}..."
      continue
    fi
    # Should we get this one elsewhere/different branch?
    if [ -v 'NONSTD["${LOC}"]' ]; then
      GITURI=$(echo ${NONSTD[${LOC}]} | cut -d# -f1)
      [ -z "$GITURI" ] && GITURI="${KDEGITURI}"
      BRANCH=$(echo ${NONSTD[${LOC}]} | cut -d# -f2)
      if [ "${BRANCH}" == "${GITURI}" ] ||  [ -z "${BRANCH}" ]; then
        # No branch specified:
        BRANCH=${DEFBRANCH}
      fi
      echo ">>     Fetching ${SET}:${LOC} from ${GITURI} branch ${BRANCH}..."
    else
      GITURI=${KDEGITURI}
      BRANCH=${DEFBRANCH}
    fi
    # Check for name transformation:
    if [ -v 'PKGSRC["${LOC}"]' ]; then
      echo ">>     Remote ${REM} --> local ${LOC}..."
      REM=${PKGSRC["${LOC}"]}
    else
      REM=${LOC}
    fi
    git clone ${GITURI}${REM}.git ${SET}/${LOC}-${THEDATE}git
    if [ $? -ne 0 ]; then
      echo ">>     Failed to checkout ${SET}:${LOC}."
      continue
    fi
    pushd ${SET}/${LOC}-${THEDATE}git
      git checkout ${BRANCH} # If this fails we should have 'master' anyway
      if [ $? -ne 0 ]; then
        BRANCH="master"
        git checkout ${BRANCH}
      fi
      if [ "$CUSTDATE" != "NO" ]; then
        # Checkout at a specified date instead of HEAD:
        git checkout $(git rev-list -n 1 --before="`date -d $THEDATE`" $BRANCH)
      fi
    popd
  done

  if [ $(ls ${SET}/ |grep git$ |wc -l) -gt 0 ]; then
    # Remove git meta data from the tarballs:
    if [ "$SHRINK" = "YES" ]; then
      echo ">>     Removing git metadata..."
      for DIR in $(ls ${SET} |grep git$) ; do
        find ${SET}/${DIR%/} -name ".git*" -depth -exec rm -rf {} \;
      done
    fi

    # Zip them up:
    echo ">>     Creating tarballs..."
    for DIR in $(ls ${SET} |grep git$) ; do
      if [ "$FORCE" = "NO" -a -f ${SET}/${DIR%/}.tar.xz ]; then
        echo ">> Not overwriting existng file '${SET}/${DIR%/}.tar.xz'"
        echo ">> Use '-f' to force ovewriting existing files"
      else
        cd ${SET} ; tar -Jcf ${DIR%/}.tar.xz ${DIR%/} ; cd ..
      fi
    done

    if [ "$CLEANUP" = "YES" ]; then
      # Remove the cloned directories now that we have the tarballs:
      rm -rf ${SET}/*git
    fi
  fi
done

cd $CWD
# Done!
