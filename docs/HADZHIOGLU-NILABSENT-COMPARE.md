# Hadzhioglu → nilabsent comparison

Experimental branch: `experimental/hadzhioglu-compare`

Sources checked:
- `hadzhioglu/padavan-fw` — `master`
- `nilabsent/padavan-ng` — `master`

## Batch 1 — `trunk/user/httpd`

### `image.h`

**Hadzhioglu:** exists as `trunk/user/httpd/image.h`.

**nilabsent:** `trunk/user/httpd/image.h` is absent. nilabsent instead has `image_uimage.h` and `image_tplink.h`; `image_uimage.h` has the same blob SHA as Hadzhioglu's `image.h` (`237c33ad...`), indicating the common U-Boot image definitions were renamed/split rather than simply deleted.

**Decision: DO NOT copy `image.h` as a new file.** The relevant content is already represented by `image_uimage.h`; copying the old name would create duplicate/ambiguous definitions.

### `httpd/Makefile`

Exists in both, but differs.

Hadzhioglu builds the normal object set. nilabsent additionally enables `-ffunction-sections -fdata-sections -fvisibility=hidden`, linker `--gc-sections`, and TP-Link HWID/HWREV defines.

**Decision: DO NOT replace nilabsent's Makefile.** Preserve nilabsent's build optimizations and board-specific defines.

### `common.h`

Exists in both and differs substantially in size/blob SHA (Hadzhioglu 4745 bytes; nilabsent 5587 bytes).

**Decision: DO NOT copy wholesale.** Compare individual declarations only when a missing feature is identified.

### `httpd.c`

Exists in both and differs (Hadzhioglu 30238 bytes; nilabsent 30306 bytes).

**Decision: DO NOT copy wholesale.** Function-level comparison only.

### `httpd.h`

Exists in both and differs (Hadzhioglu 8192 bytes; nilabsent 8388 bytes).

**Decision: DO NOT copy wholesale.** Function/macro-level comparison only.

### `https.c`

Exists in both and differs (Hadzhioglu 9307 bytes; nilabsent 9586 bytes).

**Decision: DO NOT copy wholesale.** nilabsent's HTTPS changes must be preserved.

### Files observed identical in the first directory sample

`aidisk.c`, `aspbw.c`, `base64.c`, `cgi.c`, `common.c`, `crc32.c`, `ej.c` had matching blob SHAs in both repositories.

**Decision: no action required.**

## Current conclusion

The first batch does **not** reveal a useful standalone HTTPD feature that should simply be copied from Hadzhioglu into nilabsent. The important differences are inside files that already exist in nilabsent, so the next step is function-level diffing, especially `web_ex.c`, `variables.c`, `initial_web_hook.c`, and the `rc` subsystem.

No firmware source file has been modified in the experimental branch yet; this commit only records the verified comparison so far.
