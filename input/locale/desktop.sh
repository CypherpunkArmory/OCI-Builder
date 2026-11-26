#!/bin/sh
# desktop.sh [firefox]: what a desktop image adds to the base's locales (setup.sh): fonts for
# the app's languages beyond Latin, Greek and Cyrillic (Chinese, Japanese and Korean in their own
# character forms; Arabic, Persian and Hindi), GTK's translations on Ubuntu, and with "firefox"
# Firefox's language packs. Run once while building a desktop image, after setup.sh.
set -e
. /etc/os-release
langs="ar ca de es fa fr hi id it ja ko pl pt ru tr vi zh-hans zh-hant"

if [ "$ID" = fedora ]; then
  dnf install -y --setopt=install_weak_deps=False google-noto-sans-cjk-fonts \
    google-noto-sans-arabic-ui-fonts google-noto-sans-devanagari-ui-fonts
  # Firefox's language packs, all in one package
  [ "$1" != firefox ] || dnf install -y --setopt=install_weak_deps=False firefox-langpacks
  dnf clean all
  exit 0
fi

if [ "$ID" = arch ] || [ "$ID" = archarm ]; then
  # Source Han Sans: the CJK fonts without Noto CJK's serif half; noto-fonts has Arabic and
  # Devanagari
  pacman -S --noconfirm --needed --overwrite '*' adobe-source-han-sans-otc-fonts noto-fonts
  # firefox-i18n-<locale>, as Debian names them
  [ "$1" != firefox ] || pacman -S --noconfirm --needed --overwrite '*' $(for l in ar ca de es-es fa fr \
    hi-in id it ja ko pl pt-br ru tr vi zh-cn zh-tw; do echo firefox-i18n-$l; done)
  yes | pacman -Scc
  exit 0
fi

if [ "$ID" = alpine ]; then
  apk add --no-cache font-noto-cjk font-noto-arabic font-noto-devanagari
  # Alpine packages no language packs: Mozilla's for this exact Firefox ESR, which Firefox loads
  # from its distribution folder (one for another version is skipped, until it is rebuilt)
  if [ "$1" = firefox ]; then
    v=$(apk info -e -v firefox-esr | sed 's/^firefox-esr-//; s/-r[0-9]*$//')
    d=/usr/lib/firefox-esr/distribution/extensions
    mkdir -p $d
    for l in ar ca de es-ES fa fr hi-IN id it ja ko pl pt-BR ru tr vi zh-CN zh-TW; do
      wget -q -O $d/langpack-$l@firefox.mozilla.org.xpi \
        https://ftp.mozilla.org/pub/firefox/releases/${v}esr/linux-x86_64/xpi/$l.xpi
    done
  fi
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
