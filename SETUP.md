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
| `project/`（项目源码） | 不定 | 用户自行管理 |

**为什么不使用 Git LFS**：PlatformIO 包和 Python 都有官方的快速 CDN，通过脚本下载比 LFS 更可靠，且不受 LFS 带宽限制。

### 便携性策略

- 使用 `uv` 安装完整版 Python（含 `DLLs/`），复制到项目 `python/` 目录
- 通过 `PLATFORMIO_CORE_DIR` 环境变量将工具链存放在 `.platformio/`
- 所有脚本使用 `%~dp0` 动态获取路径，不依赖绝对路径

---

## pio_init.bat 执行流程

```
pio_init.bat
  │
  ├─ [1/2] 设置便携版 Python
  │   ├─ 检查 python/python.exe 是否已存在
  │   ├─ 检查 uv 是否可用
  │   ├─ uv python install 3.14.5 → 下载完整 Python
  │   ├─ 复制到 python/ 目录
  │   ├─ 安装 pip
  │   └─ 安装 platformio
  │
  └─ [2/2] 下载 PlatformIO 包并编译
      ├─ 设置 PLATFORMIO_CORE_DIR=.platformio
      ├─ python -m platformio run → 触发下载
      │   ├─ toolchain-gccarmnoneeabi（ARM GCC 编译器）
      │   ├─ framework-arduinorenesas-uno（Arduino 框架）
      │   ├─ 项目 lib_deps（Adafruit 等库）
      │   └─ 其他工具（bossac, scons 等）
      └─ 编译验证
```

---

## 当初搭建时的踩坑记录

以下问题已在 `pio_init.bat` 中解决，记录以供参考。

### 问题 1：Embeddable Python 缺少 pip

Embeddable Python 精简了 `pip` 和 `ensurepip`。

**解决**：修改 `python314._pth`，取消 `import site` 的注释，启用 `site-packages` 加载。

### 问题 2：pip 启动器路径硬编码

pip 生成的 `.exe` 启动器将 Python 绝对路径写死在二进制中，换电脑报错。

**解决**：用 `python -m platformio` 替代 `Scripts\pio.exe`。

### 问题 3：缺少 _ctypes 等 C 扩展模块

Embeddable Python 不含 `DLLs/` 目录，缺少 `_ctypes.pyd`、`_socket.pyd` 等。PlatformIO 依赖的 `click` 库需要 `ctypes`。

**解决**：改用 `uv` 安装的完整版 Python，自带全部 C 扩展模块。

### 问题 4：工具链缺少 C 运行时文件

`toolchain-gccarmnoneeabi` 首次下载可能损坏，缺少 `crt0.o`、`crti.o`、`crtbegin.o` 等文件。

**解决**：删除 `.platformio/packages/toolchain-gccarmnoneeabi/`，重新运行编译触发下载。

### 问题 5：上传/调试工具未预装

`pio run` 只下载编译必要的包。OpenOCD、J-Link 在平台配置中标记为 optional。

**解决**：平台初始化时会自动处理，一般不需要额外操作。

---

## 预装内容

| 组件 | 版本 | 用途 |
|------|------|------|
| Python | 3.14.5 | 运行时 |
| PlatformIO | 6.1.19 | 构建系统 |
| renesas-ra | 1.8.0 | Uno R4 WiFi 板级支持 |
| framework-arduinorenesas-uno | 1.5.1 | Arduino 框架 |
| toolchain-gccarmnoneeabi | 7.2.1 | ARM GCC 编译器 |
| tool-bossac | 1.9.1 | BOSSA 上传工具 |
| tool-openocd | 3.12.0 | OpenOCD 调试器 |
| tool-jlink | 1.92.0 | J-Link 调试器 |
| tool-scons | 4.408.0 | 构建引擎 |

---

## 最终目录大小参考

```
python/             ~220 MB    （完整 Python + pip + PlatformIO）
.platformio/        ~620 MB    （平台 + 工具链 + 框架）
project/           （用户自备） （项目源码 + 编译缓存）
────────────────────────────────
合计               ~840 MB    （不含项目源码）
```
