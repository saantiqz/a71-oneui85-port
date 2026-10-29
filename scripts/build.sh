#!/bin/bash
# Build the A71 One UI 8.5 port images: EROFS images -> super -> sparse super
set -e   # stop immediately if any command fails

PORT=~/a71port/work/port
OUT=~/a71port/work/out
ODM=~/a71port/work/stock/super/odm.img
LIMIT=8048869376

cd "$OUT"
rm -f system.img product.img vendor.img super.raw.img super.img

for p in system product vendor; do
  echo ">>> Packing $p"
  sudo mkfs.erofs -zlz4hc,9 "$p.img" "$PORT/$p"
done
sudo chown "$USER:$USER" system.img product.img vendor.img

total=$(( $(stat -c %s system.img) + $(stat -c %s product.img) + $(stat -c %s vendor.img) + $(stat -c %s "$ODM") ))
echo ">>> Total $total / limit $LIMIT  (free $(( LIMIT - total )))"
if [ "$total" -gt "$LIMIT" ]; then echo "!!! TOO BIG"; exit 1; fi

echo ">>> Building super"
lpmake --metadata-size 65536 --metadata-slots 2 --super-name super \
  --device super:8053063680 --group qti_dynamic_partitions:$LIMIT \
  --partition system:readonly:$(stat -c %s system.img):qti_dynamic_partitions --image system=system.img \
  --partition vendor:readonly:$(stat -c %s vendor.img):qti_dynamic_partitions --image vendor=vendor.img \
  --partition product:readonly:$(stat -c %s product.img):qti_dynamic_partitions --image product=product.img \
  --partition odm:readonly:$(stat -c %s "$ODM"):qti_dynamic_partitions --image odm="$ODM" \
  --output super.raw.img
lpdump super.raw.img > ~/a71port/logs/port-super-lpdump.txt

echo ">>> Making sparse super"
# (kept raw: no sparse conversion)
# (raw image kept for flashing)
ls -la "$OUT"
echo ">>> BUILD OK"
