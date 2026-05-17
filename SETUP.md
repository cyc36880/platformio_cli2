# 环境搭建记录

本文档记录便携式 PlatformIO + Arduino 开发环境的搭建过程，包括每个步骤的目的、遇到的问题和解决方案。

---

## 背景

目标：将 Arduino 开发环境打包到一个文件夹中，复制到任何 Windows 10/11 电脑上即可直接编译和上传，无需安装任何软件或在线下载工具链。

硬件平台：Arduino Uno R4 WiFi（renesas-ra 平台）

---

## 设计决策

### Git 仓库范围

仓库只追踪脚本和文档（< 50KB），不包含大文件：

| 内容 | 大小 | 追踪方式 |
|------|------|----------|
| `.bat` 脚本 + 文档 | ~10KB | Git |
| `python/`（便携版 Python） | ~220MB | `pio_init.bat` 通过 uv 下载 |
| `.platformio/`（工具链和框架） | ~620MB | `pio_init.bat` 通过 PlatformIO 下载 |
| `.uv/`（uv 下载缓存） | ~78MB | `pio_init.bat` 期间生成，可清理 |
| `project/`（项目源码） | 不定 | 用户自行管理 |

**为什么不使用 Git LFS**：PlatformIO 包和 Python 都有官方的快速 CDN，通过脚本下载比 LFS 更可靠，且不受 LFS 带宽限制。

### 便携性策略

- 使用 `uv` 安装完整版 Python（含 `DLLs/`），复制到项目 `python/` 目录
- 通过 `PLATFORMIO_CORE_DIR` 环境变量将工具链存放在 `.platformio/`
- 通过 `UV_PYTHON_INSTALL_DIR`、`UV_CACHE_DIR` 将 uv 的下载和缓存全部限定在项目 `.uv/` 内
- `--no-shim` 禁止 uv 创建全局 Python 快捷方式
- 所有脚本使用 `%~dp0` 动态获取路径，不依赖绝对路径
- 使用 `python -m platformio` 而非 `Scripts\pio.exe`，避免 pip 启动器路径硬编码

### 缓存目录说明

| 目录 | 大小 | 用途 | 生命周期 |
|------|------|------|----------|
| `python/` | ~220MB | 便携版 Python + pip + PlatformIO | init 后持久保留 |
| `.platformio/` | ~620MB | 工具链 + 框架 + 库 | init 后持久保留 |
| `.uv/` | ~78MB | Python 安装缓存 + pip 下载缓存 | 仅 init 期间需要，可随时清理 |

---

## pio_init.bat 执行流程

```
pio_init.bat
  │
  ├─ [1/2] 设置便携版 Python
  │   ├─ 检查 python/python.exe 是否已存在
  │   ├─ 检查 uv 是否可用（不可用则报错退出）
  │   ├─ 设置 UV_PYTHON_INSTALL_DIR=.uv\python（限定缓存位置）
  │   ├─ 设置 UV_CACHE_DIR=.uv\cache
  │   ├─ 设置 UV_LINK_MODE=copy
  │   ├─ uv python install 3.14.5 --no-shim → 下载完整 Python
  │   ├─ 复制到 python/ 目录
  │   ├─ 删除 Lib\EXTERNALLY-MANAGED（解除 PEP 668 保护）
  │   └─ uv pip install pip platformio → 安装到 python/
  │
  └─ [2/2] 下载 PlatformIO 包并编译
      ├─ 设置 PLATFORMIO_CORE_DIR=.platformio
      ├─ python -m platformio run → 触发下载
      │   ├─ toolchain-gccarmnoneeabi（ARM GCC 编译器）
      │   ├─ framework-arduinorenesas-uno（Arduino 框架）
      │   ├─ 项目 lib_deps（Adafruit 等库）
      │   └─ 其他工具（bossac, scons 等）
      └─ 编译验证（即使编译失败也算成功，只要包已下载）
```

---

## 踩坑记录

以下问题已在 `pio_init.bat` 中解决，记录以供参考。

### 问题 1：Embeddable Python 缺少 pip

Embeddable Python 精简了 `pip` 和 `ensurepip`。

**解决**：修改 `python314._pth`，取消 `import site` 的注释，启用 `site-packages` 加载。后续改用 `uv` 安装的完整版 Python，不再受此影响。

### 问题 2：pip 启动器路径硬编码

pip 生成的 `.exe` 启动器将 Python 绝对路径写死在二进制中，换电脑报错。

**解决**：用 `python -m platformio` 替代 `Scripts\pio.exe`。

### 问题 3：缺少 _ctypes 等 C 扩展模块

Embeddable Python 不含 `DLLs/` 目录，缺少 `_ctypes.pyd`、`_socket.pyd` 等。PlatformIO 依赖的 `click` 库需要 `ctypes`。

**解决**：改用 `uv` 安装的完整版 Python（`uv python install`），自带全部 C 扩展模块和 `DLLs/` 目录。

### 问题 4：PEP 668 阻止 pip 安装

uv 管理的 Python 带有 `Lib\EXTERNALLY-MANAGED` 标记，禁止直接 pip 安装包。

**解决**：复制 Python 后删除该标记文件，然后用 `uv pip install --python` 安装包。

### 问题 5：工具链缺少 C 运行时文件

`toolchain-gccarmnoneeabi` 首次下载可能损坏，缺少 `crt0.o`、`crti.o`、`crtbegin.o` 等文件。

**解决**：删除 `.platformio/packages/toolchain-gccarmnoneeabi/`，重新运行编译触发下载。

### 问题 6：中文 Windows cmd 解析错误 "此时不应有 ."

三个原因叠加导致：

| 原因 | 说明 | 修复方法 |
|------|------|----------|
| `echo.` 语法 | 中文 Windows cmd 将 `echo.` 解析为语法错误 | 全部改用 `echo/` |
| `::` 注释含 `()` | 在 `()` 代码块内用 `::` 注释且注释文本含括号，cmd 混淆括号配对 | 改用 `rem` 注释 |
| `%VAR%` 在 `()` 块内展开时机 | 在 `if (...) else (...)` 块内，`%VAR%` 在解析时展开而非执行时，导致值为空 | 改用 `!VAR!`（需开启 `enabledelayedexpansion`） |
| echo 消息含括号 | `echo ... (no source code)` 在 `()` 块内被误解析 | 去掉消息中的括号 |

### 问题 7：uv 全局快捷方式警告

`uv python install` 默认尝试在 `~/.local/bin/` 创建 Python shim。即使设置了 `UV_PYTHON_INSTALL_DIR`，shim 创建仍会尝试全局写入，产生：

```
warning: Failed to install executable for cpython-3.14.5
  Caused by: Executable already exists at C:\Users\...\.local\bin\python3.14.exe but is not managed by uv
```

**解决**：添加 `--no-shim` 参数禁止创建全局 shim。

### 问题 8：PlatformIO 下载超时

PlatformIO 主镜像 `dl.registry.platformio.org` 在国内可能超时。

**解决**：PlatformIO 会自动切换镜像重试，无需额外处理。首次下载中断后，重新运行 `pio_init.bat` 会跳过已下载的包，从断点继续。

---

## 预装内容

| 组件 | 版本 | 用途 |
|------|------|------|
| Python | 3.14.5 | 运行时 |
| PlatformIO | 6.1.19 | 构建系统 |
| renesas-ra | 1.8.0 | Uno R4 WiFi 板级支持 |
| framework-arduinorenesas-uno | 1.5.1 | Arduino 框架 |
| toolchain-gccarmnoneeabi | ~1.70201.0 | ARM GCC 编译器 |
| tool-bossac | ~1.10901.0 | BOSSA 上传工具 |
| tool-scons | ~4.40801.0 | 构建引擎 |

---

## 最终目录大小参考

```
python/             ~220 MB    （完整 Python + pip + PlatformIO）
.platformio/        ~620 MB    （平台 + 工具链 + 框架 + 库）
.uv/                 ~78 MB    （uv 下载缓存，仅 init 需要）
project/           （用户自备） （项目源码 + 编译缓存）
────────────────────────────────
合计               ~920 MB    （不含项目源码）
清理 .uv/ 后        ~840 MB
```
