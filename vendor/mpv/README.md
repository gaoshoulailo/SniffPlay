# libmpv runtime

Place the 64-bit Windows `mpv-2.dll` or `libmpv-2.dll` file in this directory during development. The DLL is excluded from Git. Alternatively, set `SNIFFPLAY_MPV_DLL` to its absolute path.

## Verified LGPL-compatible build

- Build project: `zhongfly/mpv-winbuild`
- Upstream build tag: `2026-08-27-182fa6ca49`
- mpv commit: `182fa6ca49f455cadb884858f386e2f00540aeb7`
- Archive: `mpv-dev-lgpl-x86_64-20260827-git-182fa6ca49.7z`
- Download: `https://github.com/zhongfly/mpv-winbuild/releases/download/2026-08-27-182fa6ca49/mpv-dev-lgpl-x86_64-20260827-git-182fa6ca49.7z`
- Build details: `https://github.com/zhongfly/mpv-winbuild/actions/runs/33069943766`
- LGPL build patch: `https://github.com/zhongfly/mpv-winbuild/blob/2026-08-27-182fa6ca49/compile-lgpl-libmpv.patch`
- Archive SHA-256: `16cd542f7386bf1e68339b90618fe5446171fa555daa0c6d07d59be43bb903ea`
- DLL SHA-256: `63fed593a9e1b3c7e170bb38fcdf73722fa3d73b7c068f303bf2985eeec75367`
- mpv client API: `2.0.5`

The upstream LGPL profile builds mpv with `-Dgpl=false`, removes FFmpeg's `--enable-gpl` option, and excludes GPL-only dependencies including x264 and x265. FFmpeg remains built with `--enable-version3`. The mpv code is therefore LGPL-2.1-or-later, while the statically linked binary distribution must comply with LGPL-3.0-or-later.

`LGPL-2.1.txt` and `LGPL-3.0.txt` are copied into Windows packages. The build scripts and corresponding source revisions are available from the linked build project and workflow run. The upstream maintainer does not provide a legal guarantee and retains releases for a limited period, so preserve this provenance when publishing a release and mirror the archive or reproduce the build if the pinned URL expires.

## Verification

The pinned DLL passed SniffPlay's 35 automated tests and `scripts/verify_mpv.py` using decoded WAV playback on Windows x64. This confirms runtime compatibility, not legal advice or support for every media format.
