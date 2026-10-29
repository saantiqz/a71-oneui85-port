#!/bin/bash
# A71 One UI 8.5 port - post-build verifier. Run: sudo HOME=$HOME bash verify_build.sh [zip]
W=$HOME/a71port/work; OUT=$W/out; SUPER=$OUT/super.raw.img
ODM=$W/stock/super/odm.img
ZIP=${1:-$HOME/a71port/release/A71_OneUI8.5_Port_v1.0.zip}
CERT=d675a07a4ff128403479aed86bef3aaeae983111b8cdbc8ae5f0c22cdc8ae0b2
M=$(mktemp -d /tmp/a71verify.XXXX); P=0; F=0
ok(){ echo "  [OK]   $*"; P=$((P+1)); }
bad(){ echo "  [FAIL] $*"; F=$((F+1)); }
t(){ local d="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$d"; else bad "$d"; fi; }
same(){ if [ -f "$2" ] && [ -f "$3" ] && [ "$(sha256sum <"$2"|cut -c1-64)" = "$(sha256sum <"$3"|cut -c1-64)" ]; then ok "$1"; else bad "$1"; fi; }
bytes(){ local g=$(od -An -tx1 -j $(($3)) -N4 "$2" 2>/dev/null|tr -d ' \n'); [ "$g" = "$4" ] && ok "$1" || bad "$1 (got '$g', want $4)"; }
label(){ local g=$(getfattr -n security.selinux --only-values "$2" 2>/dev/null|tr -d '\0'); [ "$g" = "$3" ] && ok "$1" || bad "$1 (got '$g')"; }
cert(){ apksigner verify --print-certs "$2" 2>/dev/null|grep -q $CERT && ok "$1" || bad "$1"; }
absent(){ [ -z "$(find "${@:2}" -maxdepth 3 -type d -name "$1" 2>/dev/null)" ] && ok "$1 removed" || bad "$1 still present"; }
count(){ P=$((P+$(grep -c '\[OK\]' "$1"))); F=$((F+$(grep -c '\[FAIL\]' "$1"))); }
cleanup(){ for p in system product vendor; do umount $M/$p 2>/dev/null; done; rm -rf $M; }
trap cleanup EXIT
[ "$(id -u)" = 0 ] || { echo "run with: sudo HOME=\$HOME bash $0"; exit 1; }

echo "== 1. super image"
t "super.raw.img exists" test -f $SUPER
[ "$(stat -c%s $SUPER 2>/dev/null)" = 8053063680 ] && ok "size 8053063680" || bad "size $(stat -c%s $SUPER 2>/dev/null)"
echo "  ... reading partitions from super (1-2 min)"
python3 - "$SUPER" "$OUT" "$ODM" > $M/lp.txt <<'PY'
import struct,sys,hashlib,os
sup,out,odm=sys.argv[1:4]
f=open(sup,'rb'); f.seek(4096); g=f.read(4096)
if struct.unpack_from('<I',g,0)[0]!=0x616c4467: print("  [FAIL] LP geometry magic"); sys.exit()
maxsz,slots,lbs=struct.unpack_from('<III',g,40)
print(f"  [OK]   LP geometry (metadata {maxsz}, slots {slots})")
f.seek(4096+8192); h=f.read(maxsz)
if struct.unpack_from('<I',h,0)[0]!=0x414C5030: print("  [FAIL] LP metadata magic"); sys.exit()
hsz=struct.unpack_from('<I',h,8)[0]; d=[struct.unpack_from('<III',h,80+12*i) for i in range(4)]
tab=lambda i:[h[hsz+d[i][0]+d[i][2]*k:hsz+d[i][0]+d[i][2]*(k+1)] for k in range(d[i][1])]
nm=lambda b:b[:36].split(b'\0')[0].decode()
groups=[(nm(x),struct.unpack_from('<Q',x,40)[0]) for x in tab(2)]
gd=dict(groups)
print(("  [OK]  " if gd.get('qti_dynamic_partitions')==8048869376 else "  [FAIL]")+f" group qti_dynamic_partitions limit {gd.get('qti_dynamic_partitions')}")
ex=tab(1); parts={}
for p in tab(0):
    a,fe,ne,gi=struct.unpack_from('<IIII',p,36)
    parts[nm(p)]=[struct.unpack_from('<QIQI',ex[fe+k],0) for k in range(ne)]
print(f"  [OK]   partitions in super: {', '.join(sorted(parts))}")
def stream(e,n):
    hh=hashlib.sha256(); left=n
    for secs,typ,data,src in e:
        f.seek(data*512); r=min(secs*512,left)
        while r>0:
            b=f.read(min(16<<20,r)); hh.update(b); r-=len(b); left-=len(b)
        if left<=0: break
    return hh.hexdigest()
for name,img in [('system',out+'/system.img'),('product',out+'/product.img'),('vendor',out+'/vendor.img'),('odm',odm)]:
    if name not in parts: print(f"  [FAIL] {name} missing from super"); continue
    if not os.path.exists(img): print(f"  [FAIL] {img} missing"); continue
    n=os.path.getsize(img); cap=sum(x[0] for x in parts[name])*512
    if n>cap: print(f"  [FAIL] {name}.img bigger than partition"); continue
    hi=hashlib.sha256()
    with open(img,'rb') as i:
        for b in iter(lambda:i.read(16<<20),b''): hi.update(b)
    print(("  [OK]  " if stream(parts[name],n)==hi.hexdigest() else "  [FAIL]")+f" {name} in super == {os.path.basename(img)}")
PY
cat $M/lp.txt; count $M/lp.txt

echo "== 2. images vs port tree"
for p in system product vendor; do mkdir -p $M/$p; t "mount $p.img (erofs)" mount -t erofs -o loop,ro $OUT/$p.img $M/$p; done
for p in system product vendor; do
  echo "  ... comparing $p with port/$p (a few min)"
  diff -rq --no-dereference $W/port/$p $M/$p > $M/diff_$p.txt 2>&1
  [ -s $M/diff_$p.txt ] && { bad "$p differs from port ($(wc -l <$M/diff_$p.txt) entries):"; head -5 $M/diff_$p.txt; } || ok "$p image identical to port/$p"
done
S=$M/system/system
echo "== 3. port fixes present"
same "framework.jar (camera spoof)" $S/framework/framework.jar $W/fw/framework_a71.jar
same "services.jar (KnoxGuard/ICCC/signature/GPU-mem fix)" $S/framework/services.jar $W/jar/services_gpu.jar
same "SecSettings (port info rows)" $S/priv-app/SecSettings/SecSettings.apk $W/settings/SecSettings_mod.apk
cert "SecSettings signed with port key" $S/priv-app/SecSettings/SecSettings.apk
unzip -Z1 $S/priv-app/SecSettings/SecSettings.apk 2>/dev/null | grep -qx classes6.dex && ok "SecSettings has controller (classes6.dex)" || bad "SecSettings missing classes6.dex"
cert "SDHMS signed with port key" $S/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk
same "S21 FE camera app" $S/priv-app/SamsungCamera/SamsungCamera.apk $HOME/a71port/addons/s21fe-cam/s21fe-camera.apk
bytes "vold unlock patch @0x94d60" $S/bin/vold 0x94d60 09000014
bytes "libstagefright fread patch @0xed2a0" $S/lib64/libstagefright.so 0xed2a0 e21f8052
t "camera-feature.xml" test -f $S/cameradata/camera-feature.xml
t "floating_feature: siop_a71_sm7150" grep -q siop_a71_sm7150 $S/etc/floating_feature.xml
same "init.usb.rc = donor original" $S/etc/init/hw/init.usb.rc $HOME/a71port/logs/donor-init.usb.rc.orig
t "Velvet (Google app)" test -f $M/product/priv-app/Velvet/Velvet.apk
t "AIDL vibrator service" test -f $M/vendor/bin/hw/vendor.samsung.hardware.vibrator-service
t "AIDL vibrator vintf" test -f $M/vendor/etc/vintf/manifest/vendor.samsung.hardware.vibrator-default.xml
for a in FotaAgent SOAgent77 DiagMonAgent97 DAAgent; do absent $a $S $M/product; done
t "system ro.adb.secure=1" grep -q '^ro.adb.secure=1' $S/build.prop
t "system model SM-A715F" grep -q 'SM-A715F' $S/build.prop
t "vendor ro.adb.secure=1" grep -q '^ro.adb.secure=1' $M/vendor/default.prop
label "label SecSettings" $S/priv-app/SecSettings/SecSettings.apk u:object_r:system_file:s0
label "label vold" $S/bin/vold u:object_r:vold_exec:s0

echo "== 4. release zip"
if [ -f "$ZIP" ]; then
  echo "  ... testing $(basename $ZIP) (a few min)"
  t "zip integrity (unzip -t)" unzip -tq "$ZIP"
  unzip -p "$ZIP" META-INF/com/google/android/update-binary 2>/dev/null | grep -q "v1.0" && ok "installer banner says v1.0" || bad "installer banner missing v1.0"
  t "NOTICE.txt in zip" sh -c "unzip -Z1 '$ZIP' | grep -qx NOTICE.txt"
  python3 - "$ZIP" "$SUPER" > $M/zip.txt <<'PY'
import zipfile,hashlib,sys
z=zipfile.ZipFile(sys.argv[1]); f=open(sys.argv[2],'rb'); C=64<<20
zero=hashlib.sha256(bytes(C)).hexdigest(); bad=0; n=0
for line in z.read('super/manifest.txt').decode().split('\n'):
    p=line.split()
    if len(p)<2: continue
    i,typ=int(p[0]),p[1]; f.seek(i*C); h=hashlib.sha256(f.read(C)).hexdigest(); n+=1
    if (typ=='D' and h!=p[2]) or (typ=='Z' and h!=zero): bad+=1; print(f"  [FAIL] chunk {i} ({typ}) does not match super")
print(("  [OK]  " if bad==0 and n==120 else "  [FAIL]")+f" manifest: {n} chunks checked against super, {bad} mismatched")
PY
  cat $M/zip.txt; count $M/zip.txt
else echo "  (no zip yet: $ZIP - run again after make_zip.py)"; fi

echo "=================================="
echo "  $P passed, $F failed"
[ $F = 0 ] && echo "  >>> BUILD VERIFIED" || echo "  >>> DO NOT RELEASE - fix the FAIL lines"
exit $F
