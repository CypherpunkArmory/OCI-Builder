#!/bin/sh
# The basic desktop: openbox, a taskbar (tint2) with Terminal, Firefox and Files, and a
# desktop with the same three (PCManFM). Started by ~/.vnc/xstartup (startVNCServerStep2.sh).
export XKL_XMODMAP_DISABLE=1
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
# A plain background, and the icons where the terminal opened at the top left doesn't cover
# them: in a row above the taskbar when the desktop is upright, in a column on the right when
# it's wide. Set once; after that PCManFM keeps wherever the user drags them.
items="$HOME/.config/pcmanfm/default/desktop-items-0.conf"
if [ ! -f "$items" ]; then
  mkdir -p "$(dirname "$items")"
  w=${DIMENSIONS%x*}; h=${DIMENSIONS#*x}
  case "$w$h" in ''|*[!0-9]*) w=1024; h=768 ;; esac
  cell=$(px 84); panel=$(px 36); i=0
  {
    printf '[*]\nwallpaper_mode=color\ndesktop_bg=#37474f\ndesktop_fg=#ffffff\ndesktop_shadow=#000000\ndesktop_font=Sans 9\n'
    printf 'show_documents=0\nshow_trash=0\nshow_mounts=0\n'
    for f in terminal firefox files; do
      if [ "$h" -gt "$w" ]; then x=$(( 8 + i * cell )); y=$(( h - panel - cell - 8 ))
      else x=$(( w - cell - 8 )); y=$(( 8 + i * cell )); fi
      printf '\n[%s.desktop]\nx=%d\ny=%d\n' "$f" "$x" "$y"
      i=$((i + 1))
    done
  } > "$items"
fi
# Launch desktop entries without asking whether to run them.
[ -f "$HOME/.config/libfm/libfm.conf" ] || printf '[config]\nquick_exec=1\n' > "$HOME/.config/libfm/libfm.conf"

# On a phone-sized desktop, windows open maximized (a window wider than the screen can't be
# used). Made once from the system's openbox settings; the user's own edits are kept after.
w=${DIMENSIONS%x*}
case "$w" in ''|*[!0-9]*) w=1024 ;; esac
if [ ! -f "$HOME/.config/openbox/rc.xml" ] && [ "$w" -le 1400 ]; then
  mkdir -p "$HOME/.config/openbox"
  sed 's#<applications>#<applications><application class="*"><maximized>yes</maximized></application><application class="XTerm"><maximized>no</maximized></application>#' \
    /etc/xdg/openbox/rc.xml > "$HOME/.config/openbox/rc.xml"
fi

# Firefox scales its interface by the DPI, and its narrowest window is about 870 of its pixels
# (measured, Firefox ESR 140's default toolbar), wider than an upright phone's desktop at that
# scale: cap the scale so that window fits.
export UL_FIREFOX_SCALE=$(awk -v d="$UL_DPI" -v w="$w" 'BEGIN { s = d / 96; m = w / 870; if (m < s) s = m; if (s < 0.75) s = 0.75; printf "%.2f", s }')

tint2 -c "$HOME/.config/tint2/tint2rc" &
pcmanfm --desktop &
# A terminal at the top left, as every UserLAnd desktop opens with (started here, after the
# DPI above, so it opens at that size).
# As wide as the desktop allows, up to 80 columns (a DejaVu Sans Mono 10pt column is about
# 0.6 of 10pt at the DPI).
cols=$(( w * 72 * 10 / (UL_DPI * 10 * 6) - 1 )); [ "$cols" -gt 80 ] && cols=80; [ "$cols" -lt 30 ] && cols=30
(cd "$HOME" && sleep 1 && exec xterm -geometry ${cols}x24+0+0 -e /bin/bash --login) &
exec openbox
