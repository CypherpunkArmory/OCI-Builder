#!/bin/sh
# The desktop's Terminal (its icon, the taskbar's and Ctrl+Alt+T): a login shell in the home
# folder, as wide as the desktop allows up to 80 columns (a DejaVu Sans Mono 10pt column is
# about 0.6 of 10pt at the DPI).
w=${DIMENSIONS%x*}
case "$w" in ''|*[!0-9]*) w=1024 ;; esac
dpi=${UL_DPI:-96}
cols=$(( w * 72 / (dpi * 6) - 1 )); [ "$cols" -gt 80 ] && cols=80; [ "$cols" -lt 30 ] && cols=30
cd "$HOME" && exec xterm -geometry ${cols}x24 -e /bin/bash --login
