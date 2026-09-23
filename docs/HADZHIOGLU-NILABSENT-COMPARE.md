# Hadzhioglu → nilabsent comparison

Experimental branch: `experimental/hadzhioglu-compare`

Sources checked:
- `hadzhioglu/padavan-fw` — `dev`
- `nilabsent/padavan-ng` — `master`

## Batch 1 — `trunk/user/httpd`

### HTTPD file inventory correction

A later direct directory inventory corrected the earlier preliminary observation: **both repositories have the same 25 files in `trunk/user/httpd`**, including `image_tplink.h` and `image_uimage.h`. There is no `image.h` in either current source tree.

**Decision: no image header transfer is required.**

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

## Batch 7 — `trunk/user/rc/firewall_ex.c`

The file has different blob SHAs, but the inspected implementation through the early firewall rule-generation sections is identical between the two trees: protocol conversion, time matching, IP-range conversion, static routes, VPN client rules, MAC filter, URL/webstr filter, low-level filter and virtual-server/NAT generation all match in the inspected ranges.

The file should therefore **not** be replaced wholesale merely because its SHA differs. The remaining tail still needs function-level inspection before declaring the file fully equivalent.

**Decision so far: 🟡 function-level comparison; no transfer candidate identified.**

## Batch 8 — `trunk/user/rc/services.c`

The beginning of `services.c` is functionally equivalent for syslog/klogd/infosvr/crond/networkmap/telnetd/sshd. There is a small implementation difference in `start_syslogd()`:

- Hadzhioglu starts with `-L` unset and enables it dynamically when remote logging is configured.
- nilabsent includes `-L` in the initial argv and always supplies the remote `-R` pair only when a valid remote log address exists.

This does not justify importing the old file.

More importantly, nilabsent contains a dedicated `APP_ZAPRET` service block (`is_zapret_run`, `stop_zapret`, `start_zapret`, `restart_zapret`, `reload_zapret`). A search of the Hadzhioglu tree found no `is_zapret_run` implementation.

**Decision: KEEP nilabsent.** Zapret is nilabsent-only functionality, not a lost Hadzhioglu feature.

## Batch 9 — WebUI `n56u_ribbon_fixed`

The WebUI directories have the same broad structure, and many core pages have identical blob SHAs. Examples already verified include `Advanced_ACL2g_Content.asp`, `Advanced_ACL_Content.asp`, `Advanced_AiDisk_ftp.asp`, `Advanced_AiDisk_others.asp`, `Advanced_AiDisk_samba.asp`, `Advanced_BasicFirewall_Content.asp`, and `Advanced_Console_Content.asp`.

### `Advanced_Services_Content.asp`

This is a particularly useful example of **reorganization rather than loss**.

Hadzhioglu's page contains the Tor, Privoxy and DNSCrypt controls directly in the main Services page (`found_app_tor()`, `found_app_privoxy()`, `found_app_dnscrypt()`, their enable/config rows and handlers).

nilabsent removes those controls from the main page and separates the Services menu into dedicated pages. Its `state.js` explicitly contains:

- `Advanced_Services_DNSCrypt.asp`
- `Advanced_Services_DoH.asp`
- `Advanced_Services_DoT.asp`
- `Advanced_Services_Zapret.asp`
- `Advanced_Services_Proxy.asp`

and its service checks still reference `found_app_tor()` / `found_app_privoxy()`. Therefore the old Tor/Privoxy/DNSCrypt code was not simply lost; the WebUI was reorganized into separate service pages.

**Decision: DO NOT copy Hadzhioglu's `Advanced_Services_Content.asp`.** Keep nilabsent's split WebUI.

### `Advanced_Services_Service7.asp` / `Service8.asp`

`state.js` in both generations contains placeholder menu slots for `Advanced_Services_Service7.asp` and `Advanced_Services_Service8.asp`, but a direct file lookup in the Hadzhioglu tree returned 404 for `Service7`, and the nilabsent tree also returns 404 for `Service7`.

**Decision: NOT a missing-file candidate.** These are menu slots/placeholders, not a file that should be copied.

### USB modem page

`Advanced_Modem_others.asp` exists in nilabsent and remains referenced by its device-map and Makefile. It is therefore not a Hadzhioglu-only page that was dropped.

**Decision: KEEP nilabsent.**

## Batch 10 — WebUI file inventory

A direct filename inventory of `trunk/user/www/n56u_ribbon_fixed` gives:

- Hadzhioglu: 103 top-level entries;
- nilabsent: 110 top-level entries.

After excluding common directory entries (`aidisk`, `bootstrap`, `device-map`, `images`), the **only Hadzhioglu-only file is**:

`Nologin.asp`

The nilabsent-only WebUI files are:

- `Advanced_Services_DNSCrypt.asp`
- `Advanced_Services_DoH.asp`
- `Advanced_Services_DoT.asp`
- `Advanced_Services_Proxy.asp`
- `Advanced_Services_Zapret.asp`
- `jquery.multiSelectDropdown.css`
- `jquery.multiSelectDropdown.js`
- `qrcode.min.js`

The nilabsent-only files are consistent with its expanded/reorganized Services and VPN UI.

### `Nologin.asp`

Hadzhioglu's file is a small static page using `login_state_hook()`, displaying `login_ip_str()` and the `login_hint1/login_hint2` messages. A source search did **not** find a reference to the literal filename `Nologin.asp` in either tree.

**Decision: 🔴 do not copy yet.** It is self-contained, but until a backend redirect/reference to `Nologin.asp` is found, adding it would only add an apparently unused page.

### Directory-level inventory

Direct filename comparison currently gives:

| Directory | Hadzhioglu-only | nilabsent-only |
|---|---:|---:|
| `trunk/user/httpd` | 0 | 0 |
| `trunk/user/rc` | 0 | 1 (`vpn_wireguard.c`) |
| `trunk/user/shared` | 0 | 0 |
| `trunk/user/www/n56u_ribbon_fixed` | 1 (`Nologin.asp`) | 8 |

This is a strong indication that the useful differences are primarily **inside existing files**, not missing standalone files.

## KMS finding

The earlier search for `kms` in nilabsent mostly finds Linux DRM Kernel Mode Setting code. That is unrelated to a Windows KMS server.

The searched Hadzhioglu source tree did not reveal `vlmcsd` or a Windows KMS server. Therefore no KMS server should be copied based on the current evidence. If the KMS server was present in a specific prebuilt Hadzhioglu-based firmware, that build/package must be identified separately.

## Batch 11 — VPN/WebUI function and field inventory

For `vpncli.asp` and `vpnsrv.asp`, comparing extracted JavaScript function names and HTML form-field names found **no function or field present only in Hadzhioglu**.

nilabsent adds substantial VPN functionality, including:

- WireGuard client UI and key generation;
- AmneziaWG parameters;
- WireGuard/OpenVPN configuration import;
- VPN client access-control and IPSet selection;
- WireGuard server fields and client export/QR helpers.

Therefore the much larger nilabsent VPN pages are genuine extensions, not evidence of dropped Hadzhioglu functionality.

For `Advanced_Tweaks_Content.asp` and `Advanced_Scripts_Content.asp`, function and field inventories are identical; the detected content difference is only the `show_menu()` index.

For `Advanced_Console_Content.asp`, the functional code and fields are identical; differences are the menu index and textarea presentation.

For `Advanced_Services_Content.asp`, Hadzhioglu-only fields/functions are exactly the Tor/Privoxy/DNSCrypt controls moved into nilabsent's dedicated Services pages. Searches confirm the same `tor_enable`, `privoxy_enable`, and `dnscrypt_enable` functionality remains in nilabsent.

## Current rule

We are not doing whole-file replacements. The working rule is:

- 🟢 standalone file missing in nilabsent and self-contained → candidate for transfer;
- 🟡 file exists in both → compare functions/definitions and transfer only the required fragment;
- 🔴 older implementation conflicts with newer nilabsent functionality → do not transfer;
- 🔵 nilabsent-only feature → preserve it; it is not a missing Hadzhioglu feature.

No firmware source file has been modified yet. The experimental branch contains only the comparison documentation.
