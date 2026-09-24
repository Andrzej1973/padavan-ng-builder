#!/bin/sh
set -eu

ROOTDIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PADAVAN_DIR="$ROOTDIR/padavan-ng"
OVERLAY_DIR="$ROOTDIR/overlay/padavan-ng"
USER_MAKEFILE="$PADAVAN_DIR/trunk/user/Makefile"

# Hadzhioglu keeps the vlmcsd source tree alongside its package. The
# builder repository is intentionally kept small, so fetch the same source
# revision at build time before applying the overlay.
VLMCSD_DIR="$OVERLAY_DIR/trunk/user/vlmcsd"
VLMCSD_NAME="vlmcsd-svn1113"
VLMCSD_URL="https://github.com/Wind4/vlmcsd/archive/svn1113.tar.gz"
if [ ! -d "$VLMCSD_DIR/$VLMCSD_NAME" ]; then
    mkdir -p "$VLMCSD_DIR"
    wget -t5 --timeout=20 --no-check-certificate -O "$VLMCSD_DIR/$VLMCSD_NAME.tar.gz" "$VLMCSD_URL"
    tar -C "$VLMCSD_DIR" -xf "$VLMCSD_DIR/$VLMCSD_NAME.tar.gz"
    rm -f "$VLMCSD_DIR/$VLMCSD_NAME.tar.gz"
fi

# Apply only the experimental package overlay. clear_tree.sh does not
# remove these source files, so the overlay remains available to the build.
if [ -d "$OVERLAY_DIR" ]; then
    cp -a "$OVERLAY_DIR"/. "$PADAVAN_DIR"/
fi

PATCH_FILE="$ROOTDIR/overlay/patches/0001-vlmcsd-integration.patch"
if [ -f "$PATCH_FILE" ]; then
    # Keep the patch readable in the repository while normalizing section
    # headers before patch(1). This also tolerates accidental indentation in
    # generated patch text.
    sed -i -e 's/^ diff --git/diff --git/' -e 's/^ @@/@@/' "$PATCH_FILE"
    patch -d "$PADAVAN_DIR" -p1 --forward < "$PATCH_FILE"
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
