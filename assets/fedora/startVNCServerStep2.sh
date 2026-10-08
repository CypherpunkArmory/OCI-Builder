#! /bin/bash

# Fedora has no tightvncserver, so this drives TigerVNC's Xvnc directly: one
# process that is both the X server and the VNC server. The desktop flavors
# reuse this script and differ only in /support/userland-session, which picks
# what runs on the display (openbox for minimal, startxfce4 or startlxde).

if [[ -z "${INITIAL_USERNAME}" ]]; then
  INITIAL_USERNAME="user"
fi

if [[ -z "${INITIAL_VNC_PASSWORD}" ]]; then
  INITIAL_VNC_PASSWORD="userland"
fi

if [[ -z "${DIMENSIONS}" ]]; then
  DIMENSIONS="1024x768"
fi

if [[ -z "${VNC_DISPLAY}" ]]; then
  VNC_DISPLAY="51"
fi

VNC_DIR=/home/$INITIAL_USERNAME/.vnc
PID_FILE=$VNC_DIR/localhost:${VNC_DISPLAY}.pid
mkdir -p $VNC_DIR

if [ ! -f $VNC_DIR/passwd ]; then
  echo "$INITIAL_VNC_PASSWORD" | vncpasswd -f > $VNC_DIR/passwd
  chmod 600 $VNC_DIR/passwd
fi

# A server left over from an earlier session would hold the display and port.
if [ -f $PID_FILE ]; then
  kill $(cat $PID_FILE) 2>/dev/null
  rm -f $PID_FILE
fi
rm -f /tmp/.X${VNC_DISPLAY}-lock /tmp/.X11-unix/X${VNC_DISPLAY}
mkdir -p /tmp/.X11-unix 2>/dev/null

cd ~
# -noreset: an X server otherwise resets whenever its last client disconnects,
# dropping every client still connecting. The session's first client is
# xsetroot, which exits at once -- so on a first start, where openbox and the
# xterm were a moment slower to connect, they were thrown off and the desktop
# came up as a bare gray screen.
Xvnc :${VNC_DISPLAY} -geometry ${DIMENSIONS} -depth 24 -noreset \
  -rfbauth $VNC_DIR/passwd -SecurityTypes VncAuth -AlwaysShared \
  > $VNC_DIR/Xvnc.log 2>&1 < /dev/null &
XVNC_PID=$!

export DISPLAY=:${VNC_DISPLAY}

# Wait until the display actually answers, not just until its socket exists,
# before anything draws on it. UserLAnd connects as soon as the pid file
# appears, so it is written only after this.
for i in $(seq 1 30); do
  xsetroot -cursor_name left_ptr > /dev/null 2>&1 && break
  kill -0 $XVNC_PID 2>/dev/null || break
  sleep 1
done

/support/userland-session > $VNC_DIR/session.log 2>&1 < /dev/null &
xterm -geometry 80x24+0+0 -e /bin/bash --login > /dev/null 2>&1 < /dev/null &

echo $XVNC_PID > $PID_FILE
