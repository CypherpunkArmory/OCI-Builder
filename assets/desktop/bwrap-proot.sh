#!/bin/sh
# Installed as /usr/local/bin/bwrap, ahead of the real one in PATH. glycin (GTK's image loading
# since gdk-pixbuf 2.44) runs every image decoder in a bubblewrap sandbox, which can't be made
# under proot (no user namespaces through ptrace): there it would leave the desktop without
# icons or background. Under proot, run the command without the sandbox, as glycin itself does
# in Flatpak development builds; everywhere else (QEMU, the VM, the cloud) use the real bwrap.
if ! grep -q '^TracerPid:[[:space:]]*[1-9]' /proc/self/status 2>/dev/null; then
  exec /usr/bin/bwrap "$@"
fi
while [ $# -gt 0 ]; do
  case "$1" in
    --unshare-*|--share-net|--die-with-parent|--new-session|--clearenv|--as-pid-1) shift ;;
    --chdir) cd "$2" 2>/dev/null; shift 2 ;;
    # The sandbox's own HOME and runtime folder are tmpfs mounts it would have made
    --setenv) case "$2" in HOME|XDG_RUNTIME_DIR) ;; *) export "$2=$3" ;; esac; shift 3 ;;
    --unsetenv) unset "$2"; shift 2 ;;
    --dev|--proc|--tmpfs|--dir|--mqueue|--remount-ro|--seccomp|--add-seccomp-fd|--hostname) shift 2 ;;
    --bind|--bind-try|--ro-bind|--ro-bind-try|--dev-bind|--dev-bind-try|--symlink|--chmod) shift 3 ;;
    --) shift; break ;;
    --*) echo "bwrap (UserLAnd, proot): unsupported option $1" >&2; exit 1 ;;
    *) break ;;
  esac
done
exec "$@"
