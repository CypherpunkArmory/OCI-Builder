#!/bin/sh
# The IDLE app's image: Python's IDLE on top of userland-debian.
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends openbox wmctrl
apt-get install -y --no-install-recommends idle
apt-get clean
rm -rf /var/lib/apt/lists/*
