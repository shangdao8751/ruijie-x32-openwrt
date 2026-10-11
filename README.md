# Ruijie RG-EW3200GX (X32) — OpenWrt 25.12 自建固件

用 GitHub Actions 云端编译，给**锐捷 RG-EW3200GX 标准版（X32）**出 2026 年（OpenWrt 25.12 内核线）的固件。

## 背景

- 这款路由器从未被 OpenWrt 官方收录（官方只收了 `-pro` 版）
- 2022 年网友 ericvwv 做过移植并云编译（ActionsOpenwrt），其源码 fork 现已删除
- 本仓库把他的标准版移植（DTS / 分区 / MAC 规则）**重新接到官方 openwrt-25.12 源码**上，纯云端编译

## 用法

1. 网页上点 **Actions → Build OpenWrt X32 → Run workflow**
2. 等待约 2~4 小时
3. 到 **Releases** 下载：
   - `...-initramfs-kernel.bin`（首次破壳/临时引导用）
   - `...-squashfs-sysupgrade.bin`（日常升级用）

## 移植内容（scripts/diy-part2.sh 自动打进源码）

| 文件 | 改动 |
|---|---|
| `target/linux/mediatek/dts/mt7622-ruijie-rg-ew3200gx.dts` | 新增设备树：16MB NOR 分区表（firmware @0xf0000 起 15MB+），复用官方 ruijie 共享基座 |
| `target/linux/mediatek/image/mt7622.mk` | 注册 `ruijie_rg-ew3200gx` 设备定义 |
| `.../board.d/02_network` + `.../11_fix_wifi_mac` | MAC 地址规则追加标准版（与 PRO 同规则） |

## 刷写（机器已跑着 2022 版 OpenWrt 的话）

```sh
sysupgrade -v openwrt-mediatek-mt7622-ruijie_rg-ew3200gx-squashfs-sysupgrade.bin
```

首次刷入（原厂状态）请参考 ericvwv 原 release 说明：TFTP + initramfs 引导后写入。

## 校验

刷之前先看 SHA256 和镜像里的支持字符串：

```sh
# 应能 grep 到 ruijie,rg-ew3200gx（不带 -pro）
strings xxx-squashfs-sysupgrade.bin | grep rg-ew3200gx
```

**⚠️ 不要把 `-pro` 固件刷进标准版，分区不同会变砖。**

---
基于 [P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt) 模板 · 移植原始出处 [ericvwv/ActionsOpenwrt](https://github.com/ericvwv/ActionsOpenwrt)
