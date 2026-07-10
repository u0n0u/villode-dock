# Villode Dock

一个面向 Hyprland/Wayland 的 macOS 风格 Dock，使用 GTK3、GtkLayerShell 和 Hyprland 合成器实时模糊。

## 功能

- Hyprland 实时背景模糊，不使用静态伪毛玻璃
- macOS 风格波形放大与弹性空槽
- Dock 内部拖动排序
- 按住可移除图标向上拖出解除固定
- Finder 和启动台保护项
- 废纸篓空/满图标自动切换，右键确认后可安全清空
- 运行状态指示、右键菜单和启动弹跳
- 透明输入区域与窗口防遮挡
- 空闲时停止动画刷新
- 可选连接 Villode Launcher，从启动台拖入应用并精确固定
- 检测到 [Villode Desktop](https://github.com/Villode/villode-desktop) 时显示桌面设置入口

## 适配环境

目前主要在以下环境测试：

| 项目 | 参数 |
| --- | --- |
| 系统 | CachyOS Linux，Arch 系 rolling |
| 会话 | Wayland |
| 桌面环境 | Hyprland `0.55.4` |
| Python | `3.14.6` |
| GTK3 | `3.24.52` |
| GtkLayerShell | `0.10.1` |
| 显示器 | `1920x1080 @ 144Hz` |
| 缩放 | `1.00` |

其他分辨率、缩放比例和桌面环境尚未完整验证。

## 安装

```bash
git clone https://github.com/Villode/villode-dock.git
cd villode-dock
./install.sh --with-deps
```

安装器会：

- 安装 `~/.local/bin/villode-dock`
- 安装联动拖动预览 `~/.local/bin/villode-drag-preview`
- 安装图标和署名到 `~/.local/share/villode-dock/icons/`
- 写入 `~/.config/hypr/conf.d/villode-dock.conf`
- 配置 Hyprland 实时模糊和自动启动

不修改 Hyprland 配置：

```bash
./install.sh --with-deps --no-hyprland
```

只安装，不立即启动：

```bash
./install.sh --with-deps --no-start
```

## 使用

```bash
villode-dock --daemon
villode-dock --toggle
villode-dock --reload
villode-dock --quit
```

开发目录直接运行：

```bash
./run.sh
```

## 与 Villode Launcher 联动

Villode Dock 和 Villode Launcher 是独立程序，可以分别安装。两者同时运行时，启动台会通过本地 Unix Datagram Socket 向 Dock 发送拖动位置和放下事件，实现：

- Dock 图标实时放大
- 目标位置弹性让位
- 显示真实插入空槽
- 松手后固定到当前空槽

联动不依赖网络，也不进行后台轮询。

`villode-drag-preview` 是 Dock 提供给启动台联动使用的透明 Overlay；单独使用 Dock 时不会启动它。

## 依赖

Arch:

```bash
sudo pacman -S --needed python python-gobject python-cairo gtk3 gtk-layer-shell
```

Debian/Ubuntu:

```bash
sudo apt install python3 python3-gi python3-cairo \
  gir1.2-gtk-3.0 gir1.2-gtk-layer-shell-0.1
```

Fedora:

```bash
sudo dnf install python3 python3-gobject python3-cairo gtk3 gtk-layer-shell
```

## 卸载

```bash
./uninstall.sh
```

同时删除固定图标配置：

```bash
./uninstall.sh --purge
```

## 图标署名

随附图标来自 macOSicons.com，仅用于本项目的个人、学习和非商业用途。具体署名见 [`assets/dock-icons/CREDITS.md`](assets/dock-icons/CREDITS.md)。

仓库和运行时代码均不包含 macOSicons API 密钥。

## 许可证

本项目源码公开，但不是无限制商业开源授权。个人、学习、研究和非商业使用规则见 [LICENSE](LICENSE)。
