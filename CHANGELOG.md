# Changelog

## v1.0.2 (2026-10-30)

### Fixes
- Camera: photos save again from all cameras. The camera crashed after taking a photo (ImageCodecDummyNode) because `image_codec.samsung.v2` was missing from the camera feature list (`patches/config/floating_feature-image_codec.txt`)
- NFC: Settings no longer crashes when opening NFC. The S23 FE Settings hardcodes antenna position 1, the A71 reports 2 (`patches/settings/NfcSettings-antenna-position.diff`, `patches/settings/NfcAntennaGuideDialog-antenna-position.diff`)
- Lock screen camera shortcut shows the white themed icon instead of the colored app icon (`patches/camera/SamsungCamera-keyguard-shortcut-icon.diff`)
- adb: USB debugging keeps working after a reboot. A failed Android 16 trade-in mode activation set `persist.adb.tradeinmode=-1`, which stopped adbd on every boot; it is now reset instead (`patches/config/tradeinmode.rc.diff`)

### Other
- Debug logging from v1.0 turned off (`patches/config/build.prop-v1.0.2-logging.txt`)
- Port Version in Settings and the installer show 1.0.2

### Notes
- PIN auto-confirm needs a PIN of 6+ digits (Android rule, not a bug)

## v1.0.1 (2026-10-29)

### Fixes
- Flashlight works from Quick Settings: `rear_flash` is now handed to the camera service at boot (`patches/config/init.rc-flashlight.rc`)
- Settings is translated into 111 more languages (incl. Russian and Persian). The US S23 FE Settings only ships ~10 languages; translations were merged from the global S23 FE (SM-S711B, EUX) Settings, keeping only strings our Settings uses (`scripts/merge_langs.py`)
- Samsung DeX settings appear in Settings > Connected devices: Settings hid them because the A71 has no DisplayPort node (`/sys/class/dp_sec/dex`) (`patches/settings/DexModePreferenceController-show-dex.diff`)
- DeX Quick Settings tile shows the correct on/off state, and long-pressing it opens DeX settings (`patches/launcher/DesktopModeTile-dex-tile.diff`)

### New
- Samsung DeX / desktop mode enabled (experimental): `persist.wm.debug.desktop_mode_enforce_device_restrictions=false` (`patches/config/build.prop-dex.txt`). Works on external displays (tested via scrcpy `--new-display`); the tile also enables a basic desktop on the phone screen

### Other
- Installer: recognizes an update over v1.0 in recoveries that can mount encrypted data (OrangeFox), by checking the installed system
- Port Version row in Settings shows 1.0.1
- `scripts/check_v101.sh`: pre-build check that every v1.0.1 change is in the port tree

### Known issues
- Wireless DeX to a TV untested; no "phone as touchpad" in this firmware
- DeX on the phone screen has no taskbar
- Some non-US carriers need their APN added manually
- ADB Sideload doesn't work with some TWRP builds (phone drops off USB); OrangeFox works

## v1.0
- First public release
