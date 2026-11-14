#!/bin/sh
# The gnuplot app's image: gnuplot on top of userland-debian.
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends openbox wmctrl
apt-get install -y gnuplot-x11
apt-get clean
rm -rf /var/lib/apt/lists/*
