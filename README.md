# Portable PlatformIO + Arduino 开发环境

本仓库提供一套**便携式 PlatformIO 编译环境**，配合 Arduino 项目使用。克隆后运行 `pio_init.bat` 即可自动搭建完整的离线编译环境，之后整个文件夹可复制到任意 **Windows 10/11** 电脑上直接编译和上传，无需安装任何软件。

---

## 项目目录结构

使用前请将你的 PlatformIO 项目按以下结构放入 `project/` 目录：

```
platformio_cli/
├── pio_init.bat               # 首次初始化：下载全部依赖
├── pio_build.bat              # 编译固件
├── pio_clean.bat              # 清理编译缓存
├── pio_upload.bat             # 上传固件到开发板
├── pio.bat                    # 通用 pio 命令入口
├── README.md
├── SETUP.md
│
├── python/                    # （init 自动生成）便携版 Python
├── .platformio/               # （init 自动生成）工具链和板级支持包
│
└── project/                   # 你的项目（自行添加）
    └── src/                   # PlatformIO 项目根目录
        ├── platformio.ini     # 项目配置（必须）
        ├── src/               # 源代码
        ├── lib/               # 项目库
        ├── include/           # 头文件
        └── .pio/              # 编译输出（自动生成）
```

**`project/src/platformio.ini` 示例：**

```ini
[env:uno_r4_wifi]
platform = renesas-ra
board = uno_r4_wifi
framework = arduino
build_flags = -I include

lib_deps =
    adafruit/Adafruit SH110X @ ^2.1.14
    adafruit/Adafruit QMC5883P Library @ ^1.0.2
```

---

## 快速开始

### 1. 克隆仓库

```cmd
git clone <repo-url>
cd platformio_cli
```

### 2. 添加你的项目

将 PlatformIO 项目放入 `project/src/`，确保包含 `platformio.ini`。

### 3. 初始化环境

```cmd
pio_init.bat
```

此脚本会：
- 通过 `uv` 安装便携版 Python 3.14（含必要的 C 扩展模块）
- 安装 pip 和 PlatformIO
- 根据 `platformio.ini` 下载全部工具链、框架和库
- 执行首次编译验证

**前提条件**：本机需安装 [uv](https://github.com/astral-sh/uv)（Python 包管理器）。安装方式：

```powershell
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
```

### 4. 编译

```cmd
pio_build.bat
```

编译输出在 `project\src\.pio\build\<env>\firmware.bin`。

### 5. 上传到开发板

```cmd
pio_upload.bat COM3
```

不指定端口时列出可用串口。

---

## 脚本一览

| 脚本 | 用途 | 需要网络？ |
|------|------|:---:|
| `pio_init.bat` | 下载 Python + PlatformIO + 工具链 + 库，首次编译 | 是（仅首次） |
| `pio_build.bat` | 编译固件（缺少依赖时报错） | 否 |
| `pio_clean.bat` | 清理编译缓存 + 下载缓存（安全） | 否 |
| `pio_upload.bat` | 上传固件到开发板 | 否 |
| `pio.bat` | 透传参数给 `platformio` CLI | 视命令 |

---

## 清理缓存

```cmd
pio_clean.bat          # 清理编译缓存 + 下载缓存（不需要重新联网）
pio_clean.bat -f       # 同时清理已下载的库（需要重新联网下载）
```

---

## 便携性原理

- **`python -m platformio`** 替代 `pio.exe`：pip 生成的 `.exe` 启动器路径硬编码，换电脑报错。`python -m` 动态解析模块路径，随文件夹迁移自动适配。
- **`PLATFORMIO_CORE_DIR`** 指向本地 `.platformio/`，工具链和框架随文件夹迁移。
- **`%~dp0`** 在所有 `.bat` 脚本中自动解析为脚本自身目录，不依赖绝对路径。
- **完整 Python 而非 Embeddable**：使用 `uv` 安装的完整 Python，自带 `_ctypes` 等 C 扩展模块，避免 embeddable 版本缺失 DLL 的问题。

---

## 常见问题

### 上传失败 / 找不到端口

1. 确认开发板已通过 USB 连接
2. 在设备管理器中查看 COM 口编号
3. 避免使用 USB 集线器

### `pio_build.bat` 报错依赖未安装

运行 `pio_init.bat` 初始化环境后再编译。

### 如何添加其他板型

编辑 `project/src/platformio.ini`，修改或新增 `[env:]` 配置，然后运行 `pio_init.bat`。

### 复制到其他电脑后报错

确认文件夹完整复制（特别是 `python/` 和 `.platformio/` 目录），这两个目录合计约 700MB。
