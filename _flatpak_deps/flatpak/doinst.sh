#!/bin/sh
if ! grep -q ^flatpak: /etc/group ; then
  chroot . groupadd -g 372 flatpak
  chroot . useradd -d /var/lib/flatpak -u 372 -g flatpak -s /bin/false flatpak
fi

config() {
  NEW="$1"
  OLD="$(dirname $NEW)/$(basename $NEW .new)"
  # If there's no config file by that name, mv it over:
  if [ ! -r $OLD ]; then
    mv $NEW $OLD
  elif [ "$(cat $OLD | md5sum)" = "$(cat $NEW | md5sum)" ]; then
    # toss the redundant copy
    rm $NEW
  fi
  # Otherwise, we leave the .new copy for the admin to consider...
}

preserve_perms() {
  NEW="$1"
  OLD="$(dirname $NEW)/$(basename $NEW .new)"
  if [ -e $OLD ]; then
    cp -a $OLD ${NEW}.incoming
    cat $NEW > ${NEW}.incoming
    mv ${NEW}.incoming $NEW
  fi
  config $NEW
}

preserve_perms etc/profile.d/flatpak.sh.new

# Make the flathub repositories available systemwide:
chroot . \
  /usr/bin/flatpak remote-add --user --if-not-exists \
  flathub /etc/flatpak/remotes.d/flathub.flatpakrepo

flatpak remote-list --system &> /dev/null || :
