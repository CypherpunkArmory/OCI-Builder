#!/bin/sh
# The Inky app's image: Inkscape on top of userland-debian.
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends openbox wmctrl
apt-get install -y inkscape
update-mime-database /usr/share/mime
find /usr/lib -name gdk-pixbuf-query-loaders -exec {} --update-cache \;
# Every window opens full screen at the top left: on a phone-sized desktop Inkscape's
# dialogs are otherwise placed partly off screen.
sed -i 's|</applications>|<application class="*"> <position force="yes"> <x>0</x> <y>0</y> </position> <size> <width>100%</width> <height>100%</height> </size> </application> </applications>|' /etc/xdg/openbox/rc.xml
apt-get clean
rm -rf /var/lib/apt/lists/*
