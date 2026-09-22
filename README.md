# MiniEAP for OpenWrt (SYSU 适配版)

[![Build MiniEAP IPK](https://github.com/Railgun-wiki/openwrt-minieap-sysu/actions/workflows/build.yml/badge.svg)](https://github.com/Railgun-wiki/openwrt-minieap-sysu/actions/workflows/build.yml)
[![Release](https://img.shields.io/github/v/release/Railgun-wiki/openwrt-minieap-sysu?include_prereleases)](https://github.com/Railgun-wiki/openwrt-minieap-sysu/releases)

MiniEAP 的中山大学（SYSU）校园网 OpenWrt 适配包，底层核心基于 [Railgun-wiki/minieap-sysu](https://github.com/Railgun-wiki/minieap-sysu)（v0.94.2+）。

### 🌟 核心特性
- **算法适配**：完整支持中大东校区（至善园等免 RJv3 模式）及南校/北校/珠海等宿舍区（`--module rjv3` 锐捷认证及心跳）。
- **完善的日志系统**：深度接入 OpenWrt 系统日志（`syslog / logread -e minieap`）与 `/var/log/minieap.log`，内置 256KB 自动截断保护，防止路由器 tmpfs 内存爆满。
- **网卡状态检测**：自动检测网卡物理链路（`IFF_UP` / `IFF_RUNNING`），网卡错误时自动枚举系统中可用的物理网卡名称。
- **现代化守护进程**：内置 OpenWrt 标准 `procd` 服务管理脚本（`/etc/init.d/minieap`），支持进程异常崩溃自动拉起。
- **双重接入方式**：既支持标准 procd 守护模式，也支持 OpenWrt 原生 `netifd` 网络协议插件。
- **自动化构建**：GitHub Actions 支持一键编译生成各主流路由器架构的 `.ipk` 安装包。

---

## 快速安装（推荐）

直接前往 [Releases](https://github.com/Railgun-wiki/openwrt-minieap-sysu/releases) 页面下载适合你路由器 CPU 架构的 `.ipk` 文件：
- **`ramips-mt7621`**（`mipsel_24kc`）：如 Newifi 3 (D2)、斐讯 K2P、小米路由 R3G / AC2100、红米 AC2100 等。
- **`mediatek-filogic`**（`aarch64_cortex-a53`）：如 红米 AX6000、360 T7、H3C NX30 Pro 等。
- **`x86-64`**（`x86_64`）：各类 X86 软路由。

将下载好的 `.ipk` 上传到路由器安装：
```sh
scp minieap_*.ipk root@192.168.1.1:/tmp/
ssh root@192.168.1.1
opkg update
opkg install /tmp/minieap_*.ipk
```

---

## 本地编译构建

### 前置要求
1. Linux 环境（Ubuntu / Debian / WSL2 等）
2. Docker

### 编译步骤

1. 根据路由器型号确定 CPU 平台：[OpenWrt Table of Hardware](https://toh.openwrt.org/)
   - 例如 **Newifi 3 (D2)**：平台为 `ramips/mt7621`，选择 `immortalwrt/sdk:ramips-mt7621-23.05.4`
   - 例如 **Redmi AX6000**：平台为 `mediatek/filogic`，选择 `immortalwrt/sdk:mediatek-filogic-23.05.4`

2. 运行构建命令：
   ```sh
   # 克隆本仓库
   git clone -b dev https://github.com/Railgun-wiki/openwrt-minieap-sysu minieap

   # 以 MT7621 为例进行编译
   docker run -u 0:0 --rm \
       -v ./minieap:/home/build/immortalwrt/package/minieap \
       -v ./output:/home/build/immortalwrt/bin \
       immortalwrt/sdk:ramips-mt7621-23.05.4 \
       /bin/bash -c "make defconfig && make package/minieap/compile V=s -j\$(nproc)"

   # 收集生成的 IPK
   find output/ -name "minieap*.ipk"
   ```

---

## 使用指南

### 方式一：命令行配置 + procd 守护服务（简单快捷）

1. **测试运行并保存配置**：
   ```sh
   # 东校区至善园（默认标准模式）
   minieap -u <学号/NetID> -p <密码> -n <WAN物理接口名> -w

   # 其他宿舍区（启用 rjv3 插件）
   minieap -u <学号/NetID> -p <密码> -n <WAN物理接口名> -w --module rjv3
   ```
   > 提示：如果不知道网卡名，直接运行 `minieap -n wrong`，程序会自动列出路由器所有可用的网卡（如 `wan`、`eth0.2` 等）。  
   > `-w` 参数会自动将参数保存至 `/etc/minieap.conf`。

2. **测试无误后，停止前台进程**：
   ```sh
   minieap -k
   ```

3. **设置开机自启并启动系统守护进程**：
   ```sh
   /etc/init.d/minieap enable
   /etc/init.d/minieap start
   ```

### 方式二：配合 Web 图形界面管理

推荐搭配 [luci-app-minieap](https://github.com/kongfl888/luci-app-minieap) 使用：
1. 安装 `luci-app-minieap` 及其汉化包。
2. 登录 OpenWrt Web 后台，进入 **“服务” -> “MiniEAP”** 即可在网页中填写账号密码、选择接口并一键启用。

### 方式三：OpenWrt 原生 netifd 协议管理

在 `/etc/config/network` 中直接将接口的 `proto` 设为 `minieap`：
```uci
config interface 'wan'
    option device 'eth0.2'
    option proto 'minieap'
    option username 'your_netid'
    option password 'your_password'
    # option module 'rjv3'  # 非至善园视校区需求添加
```
重启网络后，由 OpenWrt 官方 netifd 统一调度管理。

---

## 故障排查与日志查看

- **查看实时系统日志**：
  ```sh
  logread -e minieap -f
  ```
- **查看持久化日志文件**：
  ```sh
  cat /var/log/minieap.log
  ```

---

## 致谢与上游项目
- 认证算法与核心实现：[Railgun-wiki/minieap-sysu](https://github.com/Railgun-wiki/minieap-sysu) (原作者 [undefined443/minieap-sysu](https://github.com/undefined443/minieap-sysu))
- 原始项目：[updateing/minieap](https://github.com/updateing/minieap)
- OpenWrt 原始打包方案：[ysc3839/openwrt-minieap](https://github.com/ysc3839/openwrt-minieap)
- 锐捷算法研究：[HustLion/mentohust](https://github.com/HustLion/mentohust)
