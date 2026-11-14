#!/bin/sh
# The deVStudio app's image: VS Code, Firefox and git on top of userland-debian.
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends openbox wmctrl
case "$(dpkg --print-architecture)" in
  arm64) vscode=linux-deb-arm64 ;;
  amd64) vscode=linux-deb-x64 ;;
  *) echo "unsupported architecture"; exit 1 ;;
esac
wget -O /tmp/vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=$vscode"
apt-get install -y /tmp/vscode.deb
rm -f /tmp/vscode.deb
apt-get install -y firefox-esr git
apt-get clean
rm -rf /var/lib/apt/lists/*
