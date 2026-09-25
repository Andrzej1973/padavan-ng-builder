# USB/IP integration — Hadzhioglu comparison

## Status

The WR1200JS build configuration already enables:

`CONFIG_FIRMWARE_INCLUDE_USBIP=y`

The nilabsent base tree already contains the kernel-side USB/IP support. The missing part compared with the current Hadzhioglu tree is the userspace implementation and its `sysfsutils` dependency.

## Hadzhioglu source

The current `hadzhioglu/padavan-ng` tree contains:

- `trunk/user/usbip/`
- `trunk/user/sysfsutils/`
- a `trunk/user/Makefile` entry that builds `sysfsutils` and `usbip` when `CONFIG_FIRMWARE_INCLUDE_USBIP=y`

The USB/IP userspace build produces `/usr/bin/usbip` and `/sbin/usbipd`. The USB/IP libraries are installed under `/lib`, and `libsysfs` is supplied by `sysfsutils`.

## Experimental implementation

The experimental builder now imports only these two userspace directories from the current Hadzhioglu repository using a sparse Git clone during `pre-build.sh`:

1. `trunk/user/sysfsutils`
2. `trunk/user/usbip`

No Hadzhioglu kernel sources are copied.

`pre-build.sh` also adds these build hooks to the temporary nilabsent `trunk/user/Makefile`:

```make
dir_$(CONFIG_FIRMWARE_INCLUDE_USBIP) += sysfsutils
dir_$(CONFIG_FIRMWARE_INCLUDE_USBIP) += usbip
```

This preserves the existing WR1200JS configuration and lets the normal Padavan build system compile the userspace tools only when USB/IP is enabled.

## Not added intentionally

- No WebUI was added: the Hadzhioglu USB/IP package itself does not provide a dedicated WebUI page.
- No new rc/service daemon was invented. `usbipd` is installed as a userspace daemon and can be started manually; any automatic server policy should be handled separately after confirming the desired use case.
- No kernel USB/IP implementation was copied from Hadzhioglu.

## Next validation

The next step is a real WR1200JS build. The important checks are:

- `usbip` links successfully against `libusbip` and `libsysfs`;
- `/usr/bin/usbip` exists in the image;
- `/sbin/usbipd` exists in the image;
- the required USB/IP kernel modules are present/loadable;
- `usbip list`, `usbip bind`, `usbip unbind`, `usbip attach`, and `usbip detach` work on the MT7621 target.
