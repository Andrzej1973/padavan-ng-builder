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


## Batch 12 — top-level `trunk/user` inventory and `radvd`

A direct top-level inventory of `trunk/user` shows one Hadzhioglu-only directory:

`radvd/`

nilabsent has no corresponding `trunk/user/radvd` directory. The Hadzhioglu package contains a full `radvd-2.X` source tree and a Makefile whose `romfs` target installs `radvd` as `/usr/sbin/radvd`.

However, neither Hadzhioglu nor nilabsent's `trunk/user/Makefile` contains a reference to `radvd`. The nilabsent tree does contain PPP IPv6 sample scripts that refer to an external `/usr/sbin/radvd`, and its changelog mentions historical radvd updates, but there is no current `trunk/user/radvd` source package.

**Decision: 🟡 investigate, but DO NOT transfer yet.** The package is a plausible legacy IPv6 component, but current source-level evidence does not show that the Hadzhioglu package is actually part of the normal firmware build. Copying the whole daemon without establishing its build/config integration would add unused code and possibly increase image size. The next check is the IPv6 build/config path and runtime references.


## Batch 13 — WR1200JS board/config support

A direct lookup of `trunk/configs/boards/YOUHUA/WR1200JS` produced a major difference:

- **nilabsent:** has a complete WR1200JS board package: `board.h`, `board.mk`, `kernel-3.4.x.config`, `partitions.config`;
- **current Hadzhioglu `dev`:** has no `trunk/configs/boards/YOUHUA/WR1200JS` directory and no YOUHUA board directory at all (only YOUKU appears among similarly named board directories).

The nilabsent WR1200JS partition definition is:

- Bootloader: `0x000000` / `0x30000`
- Config: `0x30000` / `0x10000`
- Factory: `0x40000` / `0x10000`
- Firmware: `0x50000` / `0xF70000`
- Storage: `0xFC0000` / `0x40000`

This matches the WR1200JS MTD layout observed during the router work, so this is not a generic MT7621 profile.

The board header also defines the actual WR1200JS GPIO/features, including reset/WPS/FN1 buttons, power/USB LED GPIOs, dual-band 2x2 radio counts, one Ethernet LED, gigabit PHYs, and one USB port. The board kernel configuration selects MT7621 ASIC, 128 MB RAM, MT7603E 2.4 GHz and MT7612E 5 GHz radios.

The associated `wr1200js.config` template enables several features relevant to the current firmware build, including USB, EXT4, FUSE, swap, XFRM/IPsec, IPSet, SFTP, StrongSwan, AmneziaWG, DNSCrypt, Stubby/DoT, DoH, ADB, EoIP, Zapret/Zapret2; WireGuard, Tor, Privoxy, iPerf3 and ZeroTier are present as optional commented selections in the template.

Git history in nilabsent identifies commit `833734c0b9b48c50ac2ad71fbf6bef6e886c8233` ("firmware: add support for Youhua WR1200JS") from 2018-10-10 and subsequent WR1200JS config updates. The searched current Hadzhioglu history did not return WR1200JS support commits.

**Decision: this is NOT a missing feature to transplant from Hadzhioglu.** It is the opposite: WR1200JS board support is a nilabsent-side feature relative to the currently checked Hadzhioglu `dev`. The board configuration should remain the canonical hardware definition for the WR1200JS branch.

## Batch 14 — current Hadzhioglu GitLab vs nilabsent: real package-level candidates

The earlier GitHub hadzhioglu/padavan-fw tree was too old/incomplete a source for this question. The current Hadzhioglu project is gitlab.com/hadzhioglu/padavan-ng, whose current trunk/user tree contains several packages that are not present as standalone directories in nilabsent/master.

Important current Hadzhioglu-only package candidates compared with nilabsent/master:

| Package | Current Hadzhioglu | nilabsent/master | Preliminary decision |
|---|---|---|---|
| vlmcsd | yes | no | strong candidate; inspect build hooks before transfer |
| ndisc6 | yes | no | likely standalone transfer candidate |
| obfs4 | yes | no | transfer only with build/toolchain dependencies |
| nfqws | yes as a package | no standalone package | do not copy: nilabsent already ships nfqws through zapret/zapret2 |
| mt7621_cpufreq | yes | no | leave aside; user's WR1200JS config has this option commented |
| sysfsutils | yes | no | likely support/dependency package for USB/IP userspace |

### vlmcsd — KMS

Current Hadzhioglu GitLab has a dedicated trunk/user/vlmcsd package. Its current tree records a recent change titled “Auto set _VLMCS srv-record if vlmcsd ON”. This is the KMS/vlmcsd feature that was not visible in the earlier GitHub hadzhioglu/padavan-fw snapshot.

The user's youhua-wr1200js/build.config already contains CONFIG_FIRMWARE_INCLUDE_VLMCSD=y, but the current nilabsent WR1200JS template does not define this symbol and the nilabsent source search does not find vlmcsd or CONFIG_FIRMWARE_INCLUDE_VLMCSD.

Decision: confirmed high-priority candidate for deeper inspection. Do not copy the directory yet: we need the current Hadzhioglu trunk/user/Makefile integration and exact package files, then transplant the minimal package/build hook into the experimental branch.

### ndisc6 / rdisc6

Current Hadzhioglu has a dedicated ndisc6 package and explicitly documents the build option in the directory listing as CONFIG_FIRMWARE_INCLUDE_NDISC6_RDISC6=y.

The user's build.config has this option enabled. The current nilabsent WR1200JS template has no corresponding option and nilabsent has no trunk/user/ndisc6 directory.

Decision: strong candidate for transfer, subject to checking its Makefile and adding the corresponding build variable minimally.

### obfs4

Current Hadzhioglu has a dedicated obfs4 package and its current tree records an obfs4 package update. The user's WR1200JS config has CONFIG_FIRMWARE_INCLUDE_OBFS4=y.

The current nilabsent WR1200JS template does not define the option and nilabsent has no standalone trunk/user/obfs4 package.

Decision: candidate, but not a blind copy. obfs4 is substantially larger than ndisc6/vlmcsd and depends on its Go build/package arrangement.

### Important config mismatch

The user's build.config is not equivalent to the current nilabsent WR1200JS template.

Active options in the user's config that are absent from the current nilabsent WR1200JS template include:

- CONFIG_FIRMWARE_INCLUDE_USBIP
- CONFIG_FIRMWARE_INCLUDE_SOCAT
- CONFIG_FIRMWARE_INCLUDE_NDISC6_RDISC6
- CONFIG_FIRMWARE_INCLUDE_OBFS4
- CONFIG_FIRMWARE_INCLUDE_VLMCSD

Several other user-enabled options are present in nilabsent but currently commented there, including CPU sleep, HID, QoS/IMQ/IFB, WireGuard, Tor/GeoIP, Privoxy, iPerf3, ZeroTier, Shadowsocks and image-size optimization.

This does not mean the user's current build is broken or incomplete. It means the configuration file and the current nilabsent board template have diverged, and some symbols may depend on custom or legacy build logic that is not in nilabsent/master.

### Current priority

1. vlmcsd — inspect exact source and Makefile hook
2. ndisc6 — inspect exact source and Makefile hook
3. obfs4 — inspect package and toolchain dependencies
4. sysfsutils — check whether it is required by the nilabsent USB/IP implementation
5. mt7621_cpufreq — leave aside unless we explicitly decide to experiment with CPU frequency

No firmware source code has been copied yet.
## Batch 15 — refine the config-drift candidates

Direct source searches against current nilabsent/master give three especially clear results:

- ndisc6/rdisc6: no current source references or standalone package were found.
- obfs4: no current source references or standalone package were found.
- vlmcsd: no current source references or standalone package were found.

Therefore these three are genuine source-level candidates to recover from current Hadzhioglu, provided their build integration is ported.

Two other user-config options need a different treatment:

- CONFIG_FIRMWARE_INCLUDE_NFQWS: nilabsent already contains nfqws and nfqws2 under trunk/user/zapret/zapret and trunk/user/zapret/zapret2. The Makefiles install them as /usr/bin/nfqws and /usr/bin/nfqws2. Do not transplant the older Hadzhioglu nfqws package.
- CONFIG_FIRMWARE_INCLUDE_USBIP: nilabsent contains the USB/IP kernel and userspace source under Linux staging, so the feature itself exists. The current WR1200JS template simply does not expose the user's old config symbol. Treat this as a build-system/config integration question, not as a missing source package.
- CONFIG_FIRMWARE_INCLUDE_SOCAT: nilabsent contains a socat package, so likewise it is not a missing source package. The missing symbol in the current WR1200JS template needs build-system investigation before any transfer.

sysfsutils is different again: nilabsent's USB/IP userspace README lists sysfsutils >= 2.0.0 as a dependency, while the current nilabsent tree has no standalone sysfsutils package. The current Hadzhioglu tree does. Therefore sysfsutils is a dependency candidate to investigate together with USB/IP, not an independent user feature.

Current highest-value recovery candidates are now: vlmcsd, ndisc6/rdisc6 and obfs4.
## Batch 16 — correction: USBIP and SOCAT are also current Hadzhioglu-only user packages

A fresh direct inventory of nilabsent/master trunk/user has 78 top-level entries and does NOT contain standalone socat or usbip directories.

Current Hadzhioglu GitLab does contain both socat and usbip directories in trunk/user.

Therefore the earlier Batch 14 wording that treated socat as already present in nilabsent was incorrect and is superseded by this batch.

USB/IP needs to be treated as a two-part feature: nilabsent contains the Linux 3.4 USB/IP kernel/userspace source under the kernel staging tree, but it lacks the current Hadzhioglu trunk/user usbip package/build integration. The user config has CONFIG_FIRMWARE_INCLUDE_USBIP=y, so this is a concrete candidate for restoring the user-space build integration, likely together with sysfsutils.

SOCAT is also a current Hadzhioglu user package but has no standalone socat directory in nilabsent/master. The user config has CONFIG_FIRMWARE_INCLUDE_SOCAT=y, so it is another concrete candidate to inspect before the next experimental source commit.

Updated high-priority candidate set for the user's active build.config:

1. vlmcsd / KMS
2. ndisc6 + rdisc6
3. obfs4
4. usbip + sysfsutils
5. socat

NFQWS remains excluded from this transfer list because nilabsent already provides nfqws/nfqws2 through its zapret and zapret2 packages.
mt7621_cpufreq remains excluded for now because the user's option is commented.
## Batch 17 — KMS/vlmcsd integration is a real missing source feature

Using the current `hadzhioglu/padavan-ng` GitHub repository, the comparison found more than the standalone `vlmcsd` package:

- `trunk/user/Makefile` adds `CONFIG_FIRMWARE_INCLUDE_VLMCSD -> vlmcsd`.
- `trunk/user/shared/cflags.mk` adds `-DAPP_VLMCSD`.
- `trunk/user/httpd/common.h` defines the event bit `EVM_RESTART_VLMCSD` and event type `EVT_RESTART_VLMCSD`.
- `trunk/user/shared/notify_rc.h` defines `restart_vlmcsd`.
- `trunk/user/rc/rc.h` declares the start/stop/restart functions.
- `trunk/user/rc/services.c` implements the service lifecycle and starts/stops it with the normal services.
- `trunk/user/rc/rc.c` handles the restart notification and restarts DHCPD as part of KMS configuration changes.
- `trunk/user/rc/services_ex.c` publishes `_VLMCS._tcp` through dnsmasq when `vlmcsd_enable=1`.
- `trunk/user/shared/defaults.c` provides `vlmcsd_enable=0` by default.
- `trunk/user/httpd/variables.c` registers the NVRAM variable and the restart event.
- `trunk/user/httpd/web_ex.c` exposes `found_app_vlmcsd` through the firmware capability hook.
- current Hadzhioglu `Advanced_Services_Content.asp` has a KMS toggle using `vlmcsd_enable` and hides it when `found_app_vlmcsd()` is false.

Current nilabsent/master has none of these `APP_VLMCSD` integration pieces. Therefore KMS is a confirmed source-level functionality gap between current Hadzhioglu and nilabsent, not merely a different package layout.

### Experimental implementation

The experimental branch now contains:

- `overlay/padavan-ng/trunk/user/vlmcsd/Makefile`
- `overlay/padavan-ng/trunk/user/vlmcsd/vlmcsd.sh`
- `overlay/patches/0001-vlmcsd-integration.patch`
- corresponding build hook in `pre-build.sh`

The patch restores the backend/build integration and the firmware capability hook. The WebUI toggle itself is not yet copied; this is intentional until the current nilabsent Services page structure is reconciled with Hadzhioglu's page rather than replacing the newer nilabsent Services UI wholesale.

Local static checks completed: `pre-build.sh` passes `sh -n`, and the three package Makefiles parse successfully with GNU make. No complete firmware build has been run yet.