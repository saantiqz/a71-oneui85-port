# Changelog

## v1.0.1 (2026-10-29)

### Fixes
- Flashlight works from Quick Settings: `rear_flash` is now handed to the camera service at boot (`patches/config/init.rc-flashlight.rc`)
- Settings is translated into 111 more languages (incl. Russian and Persian). The US S23 FE Settings only ships ~10 languages; translations were merged from the global S23 FE (SM-S711B, EUX) Settings, keeping only strings our Settings uses (`scripts/merge_langs.py`)
- Samsung DeX settings appear in Settings > Connected devices: Settings hid them because the A71 has no DisplayPort node (`/sys/class/dp_sec/dex`) (`patches/settings/DexModePreferenceController-show-dex.diff`)
- DeX Quick Settings tile shows the correct on/off state, and long-pressing it opens DeX settings (`patches/launcher/DesktopModeTile-dex-tile.diff`)

### New
- Samsung DeX / desktop mode enabled (experimental): `persist.wm.debug.desktop_mode_enforce_device_restrictions=false` (`patches/config/build.prop-dex.txt`). Works on external displays (tested via scrcpy `--new-display`); the tile also enables a basic desktop on the phone screen

### Other
- Port Version row in Settings shows 1.0.1
- `scripts/check_v101.sh`: pre-build check that every v1.0.1 change is in the port tree

### Known issues
- Wireless DeX to a TV untested; no "phone as touchpad" in this firmware
- DeX on the phone screen has no taskbar
- Some non-US carriers need their APN added manually

## v1.0
- First public release
