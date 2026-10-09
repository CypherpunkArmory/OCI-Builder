#! /bin/bash

if [[ -z "${INITIAL_USERNAME}" ]]; then
  INITIAL_USERNAME="user"
fi

if [[ -z "${INITIAL_VNC_PASSWORD}" ]]; then
  INITIAL_VNC_PASSWORD="userland"
fi

if [ ! -f /home/$INITIAL_USERNAME/.vnc/passwd ]; then

prog=/usr/bin/vncpasswd

/usr/bin/expect <<EOF
spawn "$prog"
expect "Password:"
send "$INITIAL_VNC_PASSWORD\r"
expect "Verify:"
send "$INITIAL_VNC_PASSWORD\r"
expect "(y/n)?"
send "n\r"
expect eof
exit
EOF

fi

if [[ -z "${DIMENSIONS}" ]]; then
	DIMENSIONS="1024x768"
fi

vncrc_line="\$geometry = \"${DIMENSIONS}\";"
echo $vncrc_line > /home/$INITIAL_USERNAME/.vncrc

if [[ -z "${VNC_DISPLAY}" ]]; then
  VNC_DISPLAY="51"
fi

# twm (the x-window-manager here) exits at startup in a UTF-8 locale: it then needs a fontset,
# and xfonts-base alone can't supply one. A VM's session has LANG=C.UTF-8 while proot's
# usually has no LANG at all, so pin the session to C, as the Alpine and Arch images do.
cat > /home/$INITIAL_USERNAME/.vnc/xstartup <<'EOF'
#!/bin/sh
export XKL_XMODMAP_DISABLE=1
LANG=C exec /etc/X11/Xsession
EOF
chmod 755 /home/$INITIAL_USERNAME/.vnc/xstartup

rm /tmp/.X${VNC_DISPLAY}-lock
rm /tmp/.X11-unix/X${VNC_DISPLAY}
tightvncserver -kill :${VNC_DISPLAY}
tightvncserver :${VNC_DISPLAY}

while [ ! -f /home/$INITIAL_USERNAME/.vnc/localhost:${VNC_DISPLAY}.pid ]
do
  sleep 1
done
cd ~
DISPLAY=:${VNC_DISPLAY} xterm -geometry 80x24+0+0 -e /bin/bash --login &
