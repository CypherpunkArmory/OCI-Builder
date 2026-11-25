#!/bin/sh
# keep-langpack.sh DOMAIN...: copies those translation domains out of Ubuntu's language packs
# (/usr/share/locale-langpack) into /usr/share/locale, where they stay once the packs, most of
# whose 200 MB nothing here uses, are removed.
for d in "$@"; do
  for f in /usr/share/locale-langpack/*/LC_MESSAGES/"$d".mo; do
    [ -f "$f" ] || continue
    l=${f#/usr/share/locale-langpack/}; l=${l%%/*}
    mkdir -p "/usr/share/locale/$l/LC_MESSAGES"
    cp "$f" "/usr/share/locale/$l/LC_MESSAGES/"
  done
done
