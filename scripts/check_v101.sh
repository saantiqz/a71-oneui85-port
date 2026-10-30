#!/bin/bash
# Checks that every v1.0.1 change is in the port tree before building
P=~/a71port/work/port/system/system
ok=0; bad=0
pass(){ echo "  PASS  $1"; ok=$((ok+1)); }
fail(){ echo "  FAIL  $1"; bad=$((bad+1)); }
chk(){ if eval "$2" >/dev/null 2>&1; then pass "$1"; else fail "$1"; fi; }
label(){ [ "$(sudo getfattr --only-values -n security.selinux "$1" 2>/dev/null)" = "u:object_r:system_file:s0" ]; }
echo "== Flashlight"
chk "init.rc gives camera access to rear_flash" "sudo grep -q 'chown cameraserver camera /sys/class/camera/flash/rear_flash' $P/etc/init/hw/init.rc"
chk "init.rc label intact" "label $P/etc/init/hw/init.rc"
echo "== DeX unlock"
chk "build.prop has the DeX property (once)" "[ \$(sudo grep -c '^persist.wm.debug.desktop_mode_enforce_device_restrictions=false' $P/build.prop) -eq 1 ]"
chk "build.prop label intact" "label $P/build.prop"
echo "== Settings"
S=$P/priv-app/SecSettings/SecSettings.apk
chk "Settings has Persian (fa)" "sudo aapt dump configurations $S | grep -qE '^fa(\$|-)'"
chk "Settings has Russian (ru)" "sudo aapt dump configurations $S | grep -qE '^ru(\$|-)'"
chk "Settings label intact" "label $S"
chk "no old Settings oat folder" "! sudo test -e $P/priv-app/SecSettings/oat"
echo "== Launcher"
L=$P/priv-app/TouchWizHome_2017/TouchWizHome_2017.apk
chk "Launcher label intact" "label $L"
chk "no old Launcher oat folder" "! sudo test -e $P/priv-app/TouchWizHome_2017/oat"
echo "== Installer"
chk "installer says v1.0.1" "grep -q 'v1.0.1 - Built by saantiqz' ~/a71port/release/update-binary"
echo; echo "Result: $ok passed, $bad failed"
[ $bad -eq 0 ] && echo "READY TO BUILD" || echo "FIX THE FAILS FIRST"
