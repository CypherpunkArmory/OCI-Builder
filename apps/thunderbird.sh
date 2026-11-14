#!/bin/sh
# The BirdBox app's image: Thunderbird on top of userland-debian.
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends openbox wmctrl
apt-get install -y thunderbird
apt-get clean
rm -rf /var/lib/apt/lists/*
