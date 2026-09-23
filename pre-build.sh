#!/bin/sh
set -eu

ROOTDIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PADAVAN_DIR="$ROOTDIR/padavan-ng"
OVERLAY_DIR="$ROOTDIR/overlay/padavan-ng"
USER_MAKEFILE="$PADAVAN_DIR/trunk/user/Makefile"

# Apply only the experimental package overlay. clear_tree.sh does not
# remove these source files, so the overlay remains available to the build.
if [ -d "$OVERLAY_DIR" ]; then
    cp -a "$OVERLAY_DIR"/. "$PADAVAN_DIR"/
fi

append_make_dir() {
    line="$1"
    if ! grep -Fqx "$line" "$USER_MAKEFILE"; then
        printf '\n%s\n' "$line" >> "$USER_MAKEFILE"
    fi
}

# These options already exist in the WR1200JS build.config.
# The current nilabsent tree has no corresponding user-package build hooks.
append_make_dir 'dir_$(CONFIG_FIRMWARE_INCLUDE_VLMCSD) += vlmcsd'
append_make_dir 'dir_$(CONFIG_FIRMWARE_INCLUDE_NDISC6_RDISC6) += ndisc6'
append_make_dir 'dir_$(CONFIG_FIRMWARE_INCLUDE_SOCAT) += socat'

echo "Experimental Hadzhioglu package overlay applied:"
echo "  - vlmcsd / KMS"
echo "  - ndisc6 + rdisc6"
echo "  - socat"
