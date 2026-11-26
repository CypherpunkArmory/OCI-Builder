#! /bin/bash

# The basic desktop on the distributions that serve VNC with Xvfb and x11vnc (Arch and Alpine):
# the same session as Debian's (/usr/share/userland/desktop/basic-session.sh), on an X server
# the size the app asked for.

if [[ -z "${INITIAL_USERNAME}" ]]; then
  INITIAL_USERNAME="user"
fi

if [[ -z "${INITIAL_VNC_PASSWORD}" ]]; then
  INITIAL_VNC_PASSWORD="userland"
fi

export LD_LIBRARY_PATH=

VNC_DIR=/home/$INITIAL_USERNAME/.vnc
mkdir -p $VNC_DIR
if [ ! -f $VNC_DIR/passwd ]; then
  x11vnc -storepasswd $INITIAL_VNC_PASSWORD $VNC_DIR/passwd
fi

if [[ -z "${DIMENSIONS}" ]]; then
  DIMENSIONS="1024x768"
fi

if [[ -z "${VNC_DISPLAY}" ]]; then
  VNC_DISPLAY="51"
fi

# Everything started in the background here gets its own log and no terminal. Under UserLAnd
# QEMU this script runs on the guest's console shell, and anything left holding that console
# died once the command returned.
rm -f /tmp/.X${VNC_DISPLAY}-lock /tmp/.X11-unix/X${VNC_DISPLAY}
Xvfb :${VNC_DISPLAY} -screen 0 ${DIMENSIONS}x24 -nolisten tcp > $VNC_DIR/Xvfb.log 2>&1 < /dev/null &
XVFB_PID=$!
export DISPLAY=:${VNC_DISPLAY}
cd ~

# Wait until the display answers before anything draws on it.
for i in $(seq 1 30); do
  xsetroot -cursor_name left_ptr > /dev/null 2>&1 && break
  kill -0 $XVFB_PID 2>/dev/null || break
  sleep 1
done

# The session reads UL_DPI and DIMENSIONS from the app; no terminal opens by itself (the
# desktop has a Terminal icon).
export UL_DPI DIMENSIONS
/usr/share/userland/desktop/basic-session.sh > $VNC_DIR/session.log 2>&1 < /dev/null &

x11vnc -xkb -noxrecord -noxfixes -noxdamage -display :${VNC_DISPLAY} -N -usepw -shared -noshm \
  > $VNC_DIR/x11vnc.log 2>&1 < /dev/null &
VNC_PID=$!

# UserLAnd connects as soon as this script returns, so return only once x11vnc is listening.
# Under QEMU an early connection is accepted by the port forward and then dropped, and the
# viewer gives up on it rather than retrying. Android hides /proc/net/tcp from apps, so under
# proot (where an early connection is simply refused and retried) this is skipped.
VNC_PORT_HEX=$(printf '%04X' $((5900 + VNC_DISPLAY)))
if cat /proc/net/tcp > /dev/null 2>&1; then
  for i in $(seq 1 30); do
    cat /proc/net/tcp /proc/net/tcp6 2>/dev/null | awk -v p=":$VNC_PORT_HEX" '$2 ~ p"$" && $4 == "0A" {f=1} END {exit !f}' && break
    kill -0 $VNC_PID 2>/dev/null || break
    sleep 1
  done
fi

echo $VNC_PID > $VNC_DIR/localhost:${VNC_DISPLAY}.pid
