#!/bin/sh
# The FoxBox app's image: Firefox on top of userland-debian.
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends openbox wmctrl
apt-get install -y firefox-esr
apt-get clean
rm -rf /var/lib/apt/lists/*
