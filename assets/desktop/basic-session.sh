#!/bin/sh
# The basic desktop: openbox, a taskbar (tint2) with Terminal, Firefox and Files, and a
# desktop with the same three (PCManFM); no terminal opens by itself. Started by
# ~/.vnc/xstartup (startVNCServerStep2.sh).
export XKL_XMODMAP_DISABLE=1
# The locale the app chose from the phone's language (/usr/share/userland/locale.sh), or
# C.UTF-8: the VNC server is started without one.
if [ -z "$LANG$LC_ALL" ] && [ -r /usr/share/userland/locale.sh ]; then . /usr/share/userland/locale.sh; fi
[ -n "$LANG$LC_ALL" ] || export LANG=C.UTF-8
# One session bus for everything below (Firefox and GTK use it, and its accessibility bus).
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ] && command -v dbus-launch > /dev/null; then
  exec dbus-launch --exit-with-session "$0" "$@"
fi
. /usr/share/userland/desktop/apply-dpi.sh

px() { echo $(( ($1 * UL_DPI + 48) / 96 )); }
mkdir -p "$HOME/.config/tint2" "$HOME/Desktop" "$HOME/.config/libfm"
sed -e "s/@HEIGHT@/$(px 36)/g" -e "s/@ICON@/$(px 26)/g" -e "s/@GAP@/$(px 6)/g" \
    -e "s/@TASKW@/$(px 200)/g" /usr/share/userland/desktop/tint2rc.in > "$HOME/.config/tint2/tint2rc"
# The desktop's icons, once: a user who removes one keeps it removed.
if [ ! -f "$HOME/.config/userland-desktop-icons" ]; then
  cp /usr/share/userland/desktop/terminal.desktop /usr/share/userland/desktop/firefox.desktop \
     /usr/share/userland/desktop/files.desktop "$HOME/Desktop/"
  touch "$HOME/.config/userland-desktop-icons"
fi
# The background (the UserLAnd penguin, centred, at about the size the DPI makes 140 pixels)
# and the icons in a column from the top left. Set once; after that PCManFM keeps the user's
# choices and wherever they drag the icons.
items="$HOME/.config/pcmanfm/default/desktop-items-0.conf"
if [ ! -f "$items" ]; then
  mkdir -p "$(dirname "$items")"
  logo=96
  for size in 128 160 192 224 256; do [ "$size" -le "$(px 140)" ] && logo=$size; done
  cell=$(px 84); i=0
  {
    printf '[*]\nwallpaper_mode=center\nwallpaper=/usr/share/userland/desktop/logo-%s.png\n' "$logo"
    printf 'desktop_bg=#546e7a\ndesktop_fg=#ffffff\ndesktop_shadow=#000000\ndesktop_font=Sans 9\n'
    printf 'show_documents=0\nshow_trash=0\nshow_mounts=0\n'
    for f in terminal firefox files; do
      printf '\n[%s.desktop]\nx=8\ny=%d\n' "$f" $(( 8 + i * cell ))
      i=$((i + 1))
    done
  } > "$items"
fi
# Launch desktop entries without asking whether to run them, and open things with one tap.
[ -f "$HOME/.config/libfm/libfm.conf" ] || printf '[config]\nquick_exec=1\nsingle_click=1\n' > "$HOME/.config/libfm/libfm.conf"

# Openbox's settings, made once from the system's (the user's own edits are kept after): Ctrl+Alt+T
# opens a terminal, and on a phone-sized desktop windows open maximized (a window wider than the
# screen can't be used), apart from terminals, which are sized to fit.
w=${DIMENSIONS%x*}
case "$w" in ''|*[!0-9]*) w=1024 ;; esac
if [ ! -f "$HOME/.config/openbox/rc.xml" ]; then
  mkdir -p "$HOME/.config/openbox"
  apps=""
  [ "$w" -le 1400 ] && apps='<application class="*"><maximized>yes</maximized></application><application class="XTerm"><maximized>no</maximized></application>'
  sed -e "s#<applications>#<applications>$apps#" \
      -e 's#<keyboard>#<keyboard><keybind key="C-A-t"><action name="Execute"><command>/usr/share/userland/desktop/terminal.sh</command></action></keybind>#' \
    /etc/xdg/openbox/rc.xml > "$HOME/.config/openbox/rc.xml"
fi

# Firefox scales its interface by the DPI, and its narrowest window is about 870 of its pixels
# (measured, Firefox ESR 140's default toolbar), wider than an upright phone's desktop at that
# scale: cap the scale so that window fits.
export UL_FIREFOX_SCALE=$(awk -v d="$UL_DPI" -v w="$w" 'BEGIN { s = d / 96; m = w / 870; if (m < s) s = m; if (s < 0.75) s = 0.75; printf "%.2f", s }')

tint2 -c "$HOME/.config/tint2/tint2rc" &
pcmanfm --desktop &
exec openbox
