#!/bin/sh
# Starts the image's Firefox (ESR where the distribution has it). Under proot the content
# sandbox can't start (no seccomp or user namespaces through ptrace): run without it there,
# and keep Firefox from offering safe mode after a session was cut off.
if grep -q '^TracerPid:[[:space:]]*[1-9]' /proc/self/status 2>/dev/null; then
  export MOZ_FAKE_NO_SANDBOX=1
fi
export MOZ_DISABLE_AUTO_SAFE_MODE=1
for f in firefox-esr firefox; do
  command -v "$f" > /dev/null && exec "$f" "$@"
done
xmessage -center "Firefox is not installed. In a terminal: sudo apt install firefox-esr" 2>/dev/null
