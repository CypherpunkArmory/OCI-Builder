# Sourced: the locale from /etc/default/locale (which the app sets from the phone's language,
# and the user may change), or C.UTF-8 so more than ASCII shows without one.
if [ -r /etc/default/locale ]; then
  . /etc/default/locale
fi
[ -n "$LANG" ] || LANG=C.UTF-8
export LANG
[ -z "$LANGUAGE" ] || export LANGUAGE
