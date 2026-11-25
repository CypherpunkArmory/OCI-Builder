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

# The basic desktop (openbox, a taskbar, desktop icons, Firefox; see /support/desktop). UL_DPI,
# from the app, sizes it for the phone's screen; DIMENSIONS places its icons.
cat > /home/$INITIAL_USERNAME/.vnc/xstartup <<EOF
#!/bin/sh
export UL_DPI="${UL_DPI}" DIMENSIONS="${DIMENSIONS}"
exec /support/desktop/basic-session.sh
EOF
chmod 755 /home/$INITIAL_USERNAME/.vnc/xstartup

rm /tmp/.X${VNC_DISPLAY}-lock
rm /tmp/.X11-unix/X${VNC_DISPLAY}
# TightVNC 1.3.10's X server keeps a buffer about the size of the whole screen on its stack, so
# at a phone's landscape size (2268x1080 at 32 bits is 9.8MB) it overflows the default 8MB
# stack and crashes with SIGSEGV as soon as a desktop draws enough -- LXDE's panel did it within
# a minute. Give it the screen's size plus the usual 8MB.
STACK_KB=$(( ${DIMENSIONS%x*} * ${DIMENSIONS#*x} * 4 / 1024 + 8192 ))
if [ "$(ulimit -s)" != "unlimited" ] && [ "$(ulimit -s)" -lt "$STACK_KB" ]; then
  ulimit -s "$STACK_KB" 2>/dev/null || ulimit -s "$(ulimit -H -s)" 2>/dev/null
fi

tightvncserver -kill :${VNC_DISPLAY}
tightvncserver :${VNC_DISPLAY}

while [ ! -f /home/$INITIAL_USERNAME/.vnc/localhost:${VNC_DISPLAY}.pid ]
do
  sleep 1
done
# The session opens the terminal itself, once its DPI is set (minimal-session.sh).
