#!/bin/sh
# The R app's image: R on top of userland-debian.
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends openbox wmctrl
apt-get install -y --no-install-recommends r-base r-base-dev
apt-get clean
rm -rf /var/lib/apt/lists/*
