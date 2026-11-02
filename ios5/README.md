# fheroes2 for iPad 1 (iOS 5.1.1, jailbroken)

Builds fheroes2 for armv7 / iOS 5 with the Theos Linux toolchain (clang 11, iPhoneOS 9.3 SDK) inside WSL.

## How it works

| Problem on iOS 5 | Solution |
|---|---|
| No C++17 runtime (`std::filesystem`, aligned new) | Static libc++/libc++abi 11.1.0 (`build_libcxx.sh`) |
| No `clock_gettime` | `compat/compat_time.h` |
| No thread-local storage | `-Dthread_local=static` (only function-level caches use it) |
| SDL2 >= 2.0.14 needs iOS 6+ | SDL 2.0.12 patched by `patch_sdl.py` |
| No object subscripting runtime (arclite) | `compat/compat_subscript.m` |
| Theos SDK stubs miss `memcpy` & co. and look like simulator stubs | `fix_sdk.py` makes an ARM-only SDK copy |
| Symbols moved between system libraries after iOS 5 | linked with `-flat_namespace` |

Dependencies and build output live in `~/fh2deps` (outside the repository).

## Build and install

```bash
bash ios5/build_libcxx.sh   # once
bash ios5/build_sdl.sh      # once
bash ios5/build_ogg.sh      # once
bash ios5/build_mixer.sh    # once (after build_ogg.sh)
bash ios5/build_game.sh     # incremental
bash ios5/deploy.sh 192.168.1.130
bash ios5/install_demo.sh 192.168.1.130   # free HoMM2 demo data
```

Game data goes to `/var/mobile/Media/fheroes2/` (`data/`, `maps/`, `music/` from the original game).
The log of the last run is `/var/mobile/Media/fheroes2/fheroes2.log`.

Music: OGG tracks from `music/` (libvorbis), otherwise MIDI from HEROES2.AGG through SDL_mixer's Timidity
with the GUS patches from `files/timidity` (the launcher sets `TIMIDITY_CFG`).

`tests/build_cxxtest.sh` builds a small program that checks the static libc++ on the device.

## Not done yet

- Translations (`msgfmt` is needed to build `.mo` files)
- App icon
