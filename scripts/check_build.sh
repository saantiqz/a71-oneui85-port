#!/bin/bash
P=~/a71port/work/port; S=$P/system/system; V=$P/vendor; PR=$P/product
pass=0; fail=0
ok()  { echo "  PASS  $1"; pass=$((pass+1)); }
bad() { echo "  FAIL  $1"; fail=$((fail+1)); }
chk() { if eval "$2" >/dev/null 2>&1; then ok "$1"; else bad "$1"; fi; }
sha() { sudo sha256sum "$1" 2>/dev/null | cut -c1-8; }
hex() { sudo xxd -s $(($2)) -l 4 -p "$1" 2>/dev/null; }
lbl() { [ -n "$(sudo getfattr --only-values -n security.selinux "$1" 2>/dev/null | tr -d '\0')" ]; }
echo "== Framework / security"
chk "services.jar = KnoxGuard+ICCC+signature+GPU-mem fix (81efc9e6)" '[ "$(sha $S/framework/services.jar)" = 81efc9e6 ]'
chk "no services oat files"                    '! ls $S/framework/oat/*/services.* 2>/dev/null | grep -q .'
chk "vold unlock patch (0x94d60 = 09000014)"   '[ "$(hex $S/bin/vold 0x94d60)" = 09000014 ]'
echo "== Media / camera"
chk "framework.jar = camera-only One UI 8.0 (1a04417b)" '[ "$(sha $S/framework/framework.jar)" = 1a04417b ]'
chk "stale boot image removed (arm/arm64)" '[ ! -d $S/framework/arm64 -a ! -d $S/framework/arm ]'
chk "libstagefright fread fix (0xed2a0 = e21f8052)" '[ "$(hex $S/lib64/libstagefright.so 0xed2a0)" = e21f8052 ]'
chk "c2 seccomp: mremap allowed"               'sudo grep -q "^mremap: 1$" $V/etc/seccomp_policy/samsung.software.media.c2-base-policy'
chk "HW video decoders restored (9)"           '[ "$(sudo grep -c OMX.qcom.video.decoder $V/etc/media_codecs.xml)" = 9 ]'
chk "camera-feature: own file (LARGE 4624x3468)" 'sudo grep -q "BACK_CAMERA_RESOLUTION_4BY3_LARGE\" value=\"4624x3468" $S/cameradata/camera-feature.xml'
chk "camera-feature: not UN1CA file"           '! sudo cmp -s $S/cameradata/camera-feature.xml ~/a71port/reference/un1ca-sm7150/target/a71/camera/camera-feature.xml'
chk "floating: CAMID_WIDE=0"                   'sudo grep -q "CAMID_WIDE>0<" $S/etc/floating_feature.xml'
chk "floating: CAMID_UW=2"                     'sudo grep -q "CAMID_UW>2<" $S/etc/floating_feature.xml'
chk "SamsungCamera = S21FE 16.0.00.74"         'aapt dump badging $S/priv-app/SamsungCamera/SamsungCamera.apk | grep -q "versionName=.16.0.00.74"'
echo "== SDHMS / thermal"
chk "SDHMS = final build (35895e22)"           '[ "$(sha $S/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk)" = 35895e22 ]'
chk "no SDHMS oat"                             '[ ! -d $S/priv-app/SamsungDeviceHealthManagerService/oat ]'
chk "SIOP name = siop_a71_sm7150"              'sudo grep -q "SIOP_POLICY_FILENAME>siop_a71_sm7150<" $S/etc/floating_feature.xml'
echo "== Vibrator (AIDL)"
chk "AIDL vibrator service present"            'sudo test -f $V/bin/hw/vendor.samsung.hardware.vibrator-service'
chk "AIDL vibrator rc + manifest + lib"        'sudo test -f $V/etc/init/vendor.samsung.hardware.vibrator-default.rc -a -f $V/etc/vintf/manifest/vendor.samsung.hardware.vibrator-default.xml -a -f $V/lib64/vendor.samsung.hardware.vibrator-V3-ndk_platform.so'
chk "old HIDL vibrator removed"                '! sudo test -f $V/bin/hw/vendor.samsung.hardware.vibrator@2.2-service'
chk "no HIDL vibrator in vendor manifest"      '[ "$(sudo grep -c vibrator $V/etc/vintf/manifest.xml)" = 0 ]'
echo "== Apps"
chk "Velvet (Google app) present"              'sudo test -f $PR/priv-app/Velvet/Velvet.apk'
for a in priv-app/FotaAgent priv-app/SOAgent77 priv-app/DiagMonAgent97 app/DAAgent; do chk "removed: $a" "[ ! -d $S/$a ]"; done
chk "GameOptimizingService removed"            '[ ! -d $S/priv-app/GameOptimizingService ]'
echo "== Identity / debug cleanup"
for f in $S/build.prop $S/system_ext/etc/build.prop $PR/etc/build.prop; do chk "model SM-A715F in ${f#$P/}" "sudo grep -q '^ro.product.[a-z_]*.model=SM-A715F$' $f"; done
chk "ro.adb.secure=1 (system)"                 'sudo grep -q "^ro.adb.secure=1$" $S/build.prop'
chk "ro.adb.secure=1 (vendor)"                 'sudo grep -q "^ro.adb.secure=1$" $V/default.prop'
chk "no forced adb in usb config"              '! sudo grep -qE "^persist.sys.usb.config=.*adb" $S/build.prop $PR/etc/build.prop $V/default.prop'
chk "Rescue Party enabled"                     '! sudo grep -q "^persist.sys.disable_rescue" $S/build.prop'
chk "init.usb.rc = donor original"             'sudo cmp -s $S/etc/init/hw/init.usb.rc ~/a71port/logs/donor-init.usb.rc.orig'
echo "== Storage / encryption"
chk "FBEv2 in vendor fstab"                    'sudo grep -q "v2+inlinecrypt_optimized" $V/etc/fstab.default'
chk "gpuMem.bpf removed"                       '! sudo find $S/etc/bpf -name "gpuMem.bpf" | grep -q .'
echo "== SELinux labels on changed files"
for f in $S/framework/services.jar $S/bin/vold $S/lib64/libstagefright.so $S/cameradata/camera-feature.xml $S/etc/floating_feature.xml \
         $S/priv-app/SamsungCamera/SamsungCamera.apk $S/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk \
         $V/bin/hw/vendor.samsung.hardware.vibrator-service $V/etc/vintf/manifest.xml $PR/priv-app/Velvet/Velvet.apk; do
  chk "label: ${f#$P/}" "lbl $f"; done
echo "=================================="
echo "  $pass passed, $fail failed"
[ $fail = 0 ] && echo "  >>> READY TO BUILD" || echo "  >>> FIX THE FAILS BEFORE BUILDING"
