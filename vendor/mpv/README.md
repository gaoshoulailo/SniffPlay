# libmpv runtime

Place the 64-bit Windows `mpv-2.dll` or `libmpv-2.dll` file in this directory during development.
The binary is intentionally excluded from Git and should come from a trusted mpv
build that is compatible with its license.

Alternatively, set `SNIFFPLAY_MPV_DLL` to the absolute path of `mpv-2.dll`.

## Current verified development build

- Source project: `shinchiro/mpv-winbuild-cmake`
- Archive: `mpv-dev-x86_64-20260809-git-dd5d17d328.7z`
- Download: `https://sourceforge.net/projects/mpv-player-windows/files/libmpv/`
- Archive SHA-256: `c6aebf40bb722efe79090bfeb61e68625f0837770347e5a8b610aef78900cf12`
- DLL SHA-256: `965efde4c8199f942bf9ed9d3e6fbcb7dd9dc961524d5780a9ca67da53f14d0c`
- License: GPL-2.0-or-later

The GPL-2.0 license text is stored in `vendor/mpv/GPL-2.0.txt` and copied
into Windows packages during the build. Keep it with the pinned GPL libmpv build.

The DLL is installed locally and ignored by Git. Before distributing an installer,
SniffPlay must include the required GPL notices and corresponding source offer, or
switch to a verified LGPL-compatible libmpv build.
