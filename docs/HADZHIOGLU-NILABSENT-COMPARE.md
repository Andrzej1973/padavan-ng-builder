# Hadzhioglu → nilabsent comparison

Experimental branch: `experimental/hadzhioglu-compare`

Sources checked:
- `hadzhioglu/padavan-fw` — `dev`
- `nilabsent/padavan-ng` — `master`

## Batch 1 — `trunk/user/httpd`

### `image.h`

**Hadzhioglu:** exists as `trunk/user/httpd/image.h`.

**nilabsent:** `trunk/user/httpd/image.h` is absent. nilabsent instead has `image_uimage.h` and `image_tplink.h`; the relevant U-Boot image definitions were reorganized rather than simply deleted.

**Decision: DO NOT copy `image.h` as a new file.** The old definitions are already represented by the newer image headers; copying the old name risks duplicate/ambiguous definitions.

### `httpd/Makefile`

Exists in both, but differs.

Hadzhioglu already uses function/data sections and `--gc-sections`. nilabsent additionally uses `-fvisibility=hidden` and has current board-specific build changes.

**Decision: DO NOT replace nilabsent's Makefile.** Preserve nilabsent's build system and only add a missing object/flag when a specific feature requires it.

### `common.h`, `httpd.c`, `httpd.h`, `https.c`

All exist in both and differ.

**Decision: DO NOT copy wholesale.** Compare individual declarations/functions only when a missing feature is identified.

### `web_ex.c`

The files share the same major infrastructure. One immediately visible difference is the POST buffer:
- Hadzhioglu: `post_buf[32768]`
- nilabsent: `post_buf[262144]`

**Decision: KEEP nilabsent.** This is an enhancement, not a missing Hadzhioglu feature.

### Files observed identical in the first directory sample

`aidisk.c`, `aspbw.c`, `base64.c`, `cgi.c`, `common.c`, `crc32.c`, `ej.c` had matching blob SHAs in both repositories.

**Decision: no action required.**

## Batch 2 — `trunk/user/httpd/variables.c` and VPN integration

A significant difference was found in `variables.c`:

Hadzhioglu has the VPN server/client ACL variables ending with `vpns_rmsk_x`.

nilabsent adds, under `APP_WIREGUARD`:

`vpns_public_x`

This is **nilabsent-only functionality**, not something missing from nilabsent. Do not import the older Hadzhioglu block over it. The corresponding WireGuard support is integrated into `httpd`, `rc`, defaults and build flags.

## Batch 3 — `trunk/user/rc/Makefile`

Both repositories contain the same major rc object set, but nilabsent has important additions:

- `vpn_wireguard.o` when `CONFIG_FIRMWARE_INCLUDE_WIREGUARD` or `CONFIG_FIRMWARE_INCLUDE_AMNEZIAWG` is enabled;
- `-fvisibility=hidden`;
- additional romfs links such as `ntpc_syncnow`, `restart_zapret`, and `update_resolvconf`;
- newer Samba condition handling with `APP_SMBD36`.

**Decision: DO NOT copy Hadzhioglu's Makefile.** nilabsent's is newer and contains functionality required by its WireGuard/AmneziaWG integration.

## Batch 4 — `trunk/user/rc/vpn_wireguard.c`

`vpn_wireguard.c` exists in nilabsent and is not present in the Hadzhioglu source tree searched.

It provides start/stop/restart/reload/update/watchdog handling for WireGuard client/server through `/usr/bin/wgs.sh` and `/usr/bin/wgc.sh`.

**Decision: KEEP nilabsent. DO NOT attempt to import a Hadzhioglu replacement.**

## Batch 5 — AmneziaWG

nilabsent contains a complete AmneziaWG kernel integration under `trunk/linux-3.4.x/net/amneziawg/`, plus build/config integration and userspace tooling. The searched Hadzhioglu tree does not contain this feature.

**Decision: KEEP nilabsent. DO NOT transplant the feature into the comparison branch merely because it is absent in Hadzhioglu.** It is a newer nilabsent feature and is especially relevant to the router's VPN configuration.

## Batch 6 — `trunk/user/rc/common_ex.c`

The first concrete difference in this file is inside `get_eeprom_params()` for TP-Link boards.

Hadzhioglu reads the LAN/2.4 GHz MAC from the `Romfile` partition at `0xf100`; if that read fails, it falls through to the standard Ralink factory offsets.

nilabsent adds a fallback attempt to read the same `0xf100` location from `MTD_PART_NAME_FACTORY` before falling through:

```c
if (i_ret < 0)
    i_ret = flash_mtd_read(MTD_PART_NAME_FACTORY, 0xf100, buffer, ETHER_ADDR_LEN);
```

**Decision: KEEP nilabsent. DO NOT copy the older Hadzhioglu implementation.** This is a board/flash-layout robustness improvement and is not a missing feature.

This also means `common_ex.c` should remain a function-level comparison target; a whole-file replacement could remove nilabsent's TP-Link factory fallback.

## KMS finding

The earlier search for `kms` in nilabsent mostly finds Linux DRM Kernel Mode Setting code. That is unrelated to a Windows KMS server.

The searched Hadzhioglu source tree did not reveal `vlmcsd` or a Windows KMS server. Therefore no KMS server should be copied based on the current evidence. If the KMS server was present in a specific prebuilt Hadzhioglu-based firmware, that build/package must be identified separately.

## Current rule

We are not doing whole-file replacements. The working rule is:

- 🟢 standalone file missing in nilabsent and self-contained → candidate for transfer;
- 🟡 file exists in both → compare functions/definitions and transfer only the required fragment;
- 🔴 older implementation conflicts with newer nilabsent functionality → do not transfer;
- 🔵 nilabsent-only feature → preserve it; it is not a missing Hadzhioglu feature.

No firmware source file has been modified yet. The experimental branch contains only the comparison documentation.
