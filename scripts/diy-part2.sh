#!/bin/bash
# Port Ruijie RG-EW3200GX (X32 non-pro) onto the OpenWrt 25.12 source tree.
# Idempotent: safe to run on a fresh clone.
set -e

PORT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "[diy] patching X32 non-pro support into $(pwd)"

# 1) device tree (uses the shared ruijie base dtsi already in 25.12)
install -m 644 "$PORT_DIR/port/dts/mt7622-ruijie-rg-ew3200gx.dts" \
  target/linux/mediatek/dts/mt7622-ruijie-rg-ew3200gx.dts
echo "[diy] + dts"

# 2) register the device in image defs (mirror of the -pro block)
IMG=target/linux/mediatek/image/mt7622.mk
if ! grep -q 'define Device/ruijie_rg-ew3200gx$' "$IMG"; then
  cat >> "$IMG" <<'EOF'

define Device/ruijie_rg-ew3200gx
  DEVICE_VENDOR := Ruijie
  DEVICE_MODEL := RG-EW3200GX
  DEVICE_DTS := mt7622-ruijie-rg-ew3200gx
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-mt7915-firmware
endef
TARGET_DEVICES += ruijie_rg-ew3200gx
EOF
  echo "[diy] + $IMG"
fi

# 3) MAC rules: reuse the exact -pro recipe (lan = label+1; 5G phy+3, 2.4G phy+2)
python3 - "$PORT_DIR" <<'PY'
import sys, pathlib
targets = [
    "target/linux/mediatek/mt7622/base-files/etc/board.d/02_network",
    "target/linux/mediatek/mt7622/base-files/etc/hotplug.d/ieee80211/11_fix_wifi_mac",
]
for t in targets:
    p = pathlib.Path(t)
    if not p.exists():
        print(f"[diy] !! missing {t}"); continue
    lines = p.read_text().splitlines(keepends=True)
    if any("rg-ew3200gx|" in l for l in lines):
        print(f"[diy] = {p.name} already patched"); continue
    out = []
    for l in lines:
        s = l.rstrip("\n")
        if s.strip() == "ruijie,rg-ew3200gx-pro)":
            indent = s[: len(s) - len(s.lstrip())]
            out.append(f"{indent}ruijie,rg-ew3200gx|\\\n")
        out.append(l)
    p.write_text("".join(out))
    print(f"[diy] + {p.name}")
PY

echo "[diy] done."
