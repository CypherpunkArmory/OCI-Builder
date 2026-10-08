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
# xsetroot, which exits at once, and the clients still connecting would be
# thrown off with it. -s 0 turns off the X server's own screen saver, which
# would otherwise blank an idle desktop after ten minutes.
Xvnc :${VNC_DISPLAY} -geometry ${DIMENSIONS} -depth 24 -noreset -s 0 \
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

# The xterm waits for the window manager to take over the screen (the
# _NET_SUPPORTING_WM_CHECK it sets on the root window), giving up after 10s.
# Mapped before that, it was not drawn until some input arrived -- the desktop
# came up a bare gray screen, most often on a first start, where openbox is
# slowest. In the background, so the pid file -- and so UserLAnd's viewer --
# does not wait on it.
(
  for i in $(seq 1 20); do
    xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | grep -q 'window id' && break
    sleep 0.5
  done
  exec xterm -geometry 80x24+0+0 -e /bin/bash --login
) > /dev/null 2>&1 < /dev/null &

echo $XVNC_PID > $PID_FILE
