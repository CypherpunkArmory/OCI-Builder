#!/bin/sh
# Sourced by each desktop's session before it starts: makes text, cursors and the terminal the
# size the app asked for. UL_DPI comes from the app (the desktop's pixels per inch on the
# phone's screen, softened); without it (an older app, or a VM that doesn't pass it) 110.
UL_DPI=${UL_DPI:-110}
case "$UL_DPI" in ''|*[!0-9]*) UL_DPI=110 ;; esac
# Font point sizes in the terminal and panel follow the DPI through Xft.dpi; pixel sizes
# (cursor, panel height, icons) are scaled from their 96 dpi sizes here.
UL_SCALE_PX() { echo $(( ($1 * UL_DPI + 48) / 96 )); }
cat > "$HOME/.Xresources.userland" <<XRES
Xft.dpi: $UL_DPI
Xft.antialias: true
Xft.hinting: true
Xft.hintstyle: hintslight
Xcursor.size: $(UL_SCALE_PX 24)
XTerm*faceName: DejaVu Sans Mono
XTerm*faceSize: 10
XTerm*background: #1e2326
XTerm*foreground: #e6e6e6
XTerm*scrollBar: false
XTerm*saveLines: 4000
XRES
xrdb -merge "$HOME/.Xresources.userland"
[ -f "$HOME/.Xresources" ] && xrdb -merge "$HOME/.Xresources"
export UL_DPI
