# One UI 8.5 port for Galaxy A71 4G (SM-A715F)

Build scripts, installer and patches for my unofficial One UI 8.5 (Android 16) port for the Galaxy A71 4G, running on the Paradigm 4.14 kernel.
Port by saantiqz, built with the help of Claude (an AI assistant made by Anthropic).

**Latest: **v1.0.1**, see [CHANGELOG.md](CHANGELOG.md).

This repo contains no Samsung or Google firmware.** Patches are published as diffs against the original files. To build, you need your own copies of the firmware.

- `scripts/`: building the super image (build.sh), pre-build checklist, post-build verifier, partition extractor, Settings language merge (v1.0.1), v1.0.1 check
- `installer/`: the TWRP installer (update-binary) and the zip packer
- `patches/services/`: services.jar changes (KnoxGuard, ICCC, platform signature, GPU-memory soft reboot fix)
- `patches/framework/`: camera-only One UI version spoof (framework.jar)
- `patches/settings/`: port info rows and controller in Settings > Software information; DeX menu without DisplayPort (v1.0.1)
- `patches/launcher/`: DeX Quick Settings tile state and long press (v1.0.1)
- `patches/config/`: config changes (floating feature, fstab/FBEv2, vintf, props, codec seccomp; v1.0.1: flashlight init.rc lines, DeX build.prop line)
- `patches/BINARY_PATCHES.md`: byte patches in vold and libstagefright

Kernel: Paradigm by pascua28 (GPL-2.0), https://github.com/pascua28/android_kernel_samsung_sm7150
UN1CA was used as a reference; a few device-specific settings (such as the FBEv2 properties) were adapted from its SM7150/A71 patches.

Not affiliated with, endorsed by or sponsored by Samsung, Google or Anthropic. All trademarks belong to their owners.
