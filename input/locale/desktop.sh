#!/bin/sh
# desktop.sh [firefox]: what a desktop image adds to the base's locales (setup.sh): fonts for
# the app's languages beyond Latin, Greek and Cyrillic (Chinese, Japanese and Korean in their own
# character forms; Arabic, Persian and Hindi), GTK's translations on Ubuntu, and with "firefox"
# Firefox ESR's language packs. Run once while building a desktop image, after setup.sh.
set -e
. /etc/os-release
langs="ar ca de es fa fr hi id it ja ko pl pt ru tr vi zh-hans zh-hant"

if [ "$ID" = fedora ]; then
  dnf install -y --setopt=install_weak_deps=False google-noto-sans-cjk-fonts \
    google-noto-sans-arabic-ui-fonts google-noto-sans-devanagari-ui-fonts
  dnf clean all
  exit 0
fi

apt-get update
apt-get install -y --no-install-recommends fonts-noto-cjk fonts-noto-ui-core

if [ "$ID" = ubuntu ]; then
  # GTK is in Ubuntu's main archive, whose translations live in language packs: take GTK's
  apt-get install -y --no-install-recommends $(for l in $langs; do echo language-pack-gnome-$l-base; done)
  /usr/share/userland/keep-langpack.sh gtk30 gtk30-properties gtk40 gtk40-properties glib20 gdk-pixbuf
  # ...and remove them, with the base packs they bring back (setup.sh removed those before)
  apt-get purge -y $(for l in $langs; do echo language-pack-gnome-$l-base language-pack-gnome-$l \
    language-pack-$l-base language-pack-$l; done) || true
  # Removing them clears the generated locales; setup.sh's list is still registered
  locale-gen
fi

if [ "$1" = firefox ]; then
  if [ "$ID" = ubuntu ]; then
    # The Mozilla team PPA's names: firefox-esr-locale-<language>
    apt-get install -y --no-install-recommends $(for l in $langs; do echo firefox-esr-locale-$l; done)
  else
    # Debian's: firefox-esr-l10n-<locale>, with a region where Firefox has more than one
    apt-get install -y --no-install-recommends $(for l in ar ca de es-es fa fr hi-in id it ja ko pl \
      pt-br ru tr vi zh-cn zh-tw; do echo firefox-esr-l10n-$l; done)
  fi
fi
apt-get clean
rm -rf /var/lib/apt/lists/*
