#! /bin/bash

if [[ -z "${INITIAL_USERNAME}" ]]; then
  INITIAL_USERNAME="user"
fi

if [[ -z "${INITIAL_VNC_PASSWORD}" ]]; then
  INITIAL_VNC_PASSWORD="userland"
fi

export LD_LIBRARY_PATH=

if [ ! -f /home/$INITIAL_USERNAME/.vnc/passwd ]; then
mkdir /home/$INITIAL_USERNAME/.vnc
x11vnc -storepasswd $INITIAL_VNC_PASSWORD /home/$INITIAL_USERNAME/.vnc/passwd
fi

if [[ -z "${DIMENSIONS}" ]]; then
	DIMENSIONS="1024x768"
fi

vncrc_line="\$geometry = \"${DIMENSIONS}\";"
echo $vncrc_line > /home/$INITIAL_USERNAME/.vncrc

if [[ -z "${VNC_DISPLAY}" ]]; then
  VNC_DISPLAY="51"
fi

# Everything started in the background here gets its own log and no terminal. Under UserLAnd
# QEMU this script runs on the guest's console shell, and anything left holding that console
# died once the command returned: x11vnc went with it, and the viewer was dropped (EOF) the
# moment it connected.
VNC_DIR=/home/$INITIAL_USERNAME/.vnc
rm /tmp/.X${VNC_DISPLAY}-lock
Xvfb :${VNC_DISPLAY} -screen 0 1024x768x16 > $VNC_DIR/Xvfb.log 2>&1 < /dev/null &
sleep 2
export DISPLAY=:${VNC_DISPLAY}
cd ~
xrdb -load $HOME/.Xresources
xsetroot -solid gray > /dev/null 2>&1 < /dev/null &
xterm -geometry 80x24+0+0 -e /bin/bash --login > /dev/null 2>&1 < /dev/null &
LANG=C twm > $VNC_DIR/twm.log 2>&1 < /dev/null &
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

echo $VNC_PID > /home/$INITIAL_USERNAME/.vnc/localhost:${VNC_DISPLAY}.pid
