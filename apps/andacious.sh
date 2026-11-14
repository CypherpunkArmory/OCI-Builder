#!/bin/sh
# The Andacious app's image: Audacity on top of userland-debian.
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends openbox wmctrl
apt-get install -y audacity
apt-get clean
rm -rf /var/lib/apt/lists/*
