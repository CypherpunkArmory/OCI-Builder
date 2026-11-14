#!/bin/sh
# The Octave app's image: GNU Octave on top of userland-debian.
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends openbox wmctrl
# libqt6sql6-sqlite: the GUI's documentation viewer needs Qt's SQLite plugin
apt-get install -y --no-install-recommends octave less octave-control octave-financial octave-io \
  octave-optim octave-signal octave-statistics octave-symbolic octave-image libqt6sql6-sqlite \
  gnuplot-x11 pstoedit fonts-freefont-otf
apt-get clean
rm -rf /var/lib/apt/lists/*
