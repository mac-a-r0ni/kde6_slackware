#!/bin/sh
# KDE additions:
KDEDIRS=/usr
export KDEDIRS

# Add KDE paths if they exist:
if [ -d /usr/libexec/kf6 ]; then
  PATH="$PATH:/usr/libexec/kf6"
fi
if [ -d /usr/libexec/kf5 ]; then
  PATH="$PATH:/usr/libexec/kf5"
fi
if [ -d /usr/lib/kde4/libexec ]; then
  PATH="$PATH:/usr/lib/kde4/libexec"
fi
export PATH

# If there's no $XDG_CONFIG_DIRS variable, set it to /etc/xdg:
if [ -z "$XDG_CONFIG_DIRS" ]; then
  XDG_CONFIG_DIRS=/etc/xdg
fi

export XDG_CONFIG_DIRS

# Commented out, since PAM should take care of this:
#if [ "$XDG_RUNTIME_DIR" = "" ]; then
#  # Using /run/user would be more in line with XDG specs, but in that case
#  # we should mount /run as tmpfs and add this to the Slackware rc scripts:
#  # mkdir /run/user ; chmod 1777 /run/user
#  # XDG_RUNTIME_DIR=/run/user/$USER
#  XDG_RUNTIME_DIR=/tmp/xdg-runtime-$USER
#  mkdir -p $XDG_RUNTIME_DIR
#  chown $USER $XDG_RUNTIME_DIR
#  chmod 700 $XDG_RUNTIME_DIR
#fi
#export XDG_RUNTIME_DIR
