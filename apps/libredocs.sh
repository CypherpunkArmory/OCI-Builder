#!/bin/sh
# The LibreDocs app's image: LibreOffice on top of userland-debian.
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends openbox wmctrl
apt-get install -y --no-install-recommends libreoffice
apt-get clean
rm -rf /var/lib/apt/lists/*
