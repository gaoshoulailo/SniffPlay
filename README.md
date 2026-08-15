# SniffPlay

嗅播音乐播放器，一个使用 Python 构建的轻量、可换肤桌面音乐搜索播放器。

## 当前阶段

项目目前已经包含：

- PySide6 + QML 桌面界面骨架
- 搜索、歌单和播放历史页面
- 可扩展的音乐数据源接口
- SQLite 本地数据存储
- 模拟搜索和播放交互
- 独立的主题变量系统
- libmpv 播放后端与不可用降级
- 本地音频选择、进度、音量和播放队列

其他音乐数据源将在后续阶段按相同 Provider 边界接入。

## libmpv

SniffPlay 使用 libmpv 负责音频解码。在 Windows 开发环境中，将 64 位
`mpv-2.dll`（也支持 `libmpv-2.dll`）放入 `vendor/mpv`，或设置 DLL 的绝对路径：

```powershell
$env:SNIFFPLAY_MPV_DLL = "D:\path\to\mpv-2.dll"
```

没有检测到 libmpv 时，应用仍可启动和管理歌单，但播放功能会明确显示为不可用。

验证 libmpv 解码和播放状态：

```powershell
.\.venv\Scripts\python scripts\verify_mpv.py
```

当前开发机已使用 `libmpv-2.dll` 完成本地 WAV 的播放、暂停、跳转和进度验证。
所用开发构建及校验信息记录在 `vendor/mpv/README.md`。该开发构建为 GPL，正式分发前
必须补齐许可证与源码提供流程，或更换为经过验证的 LGPL 构建。

开发机基线（静音播放、5 秒采样，仅供比较）：

| 状态 | 总 CPU | 工作集 |
| --- | ---: | ---: |
| 应用空闲 | 约 0.02% | 约 123 MB |
| 完整应用播放 | 约 0.20% | 约 129 MB |

## 环境要求

- Windows 10/11
- Python 3.12
- uv（推荐）或 pip

## 启动项目

使用 uv：

```powershell
uv sync --extra dev
uv run sniffplay
```

使用 Python 自带的虚拟环境：

```powershell
python -m venv .venv
.\.venv\Scripts\python -m pip install -e ".[dev]"
.\.venv\Scripts\sniffplay
```

也可以从命令行直接打开本地音频：

```powershell
.\.venv\Scripts\sniffplay "D:\Music\example.flac"
```

测试数据默认保存在 Windows 用户数据目录。开发时可通过环境变量指定位置：

```powershell
$env:SNIFFPLAY_DATA_DIR = "$PWD\data"
.\.venv\Scripts\sniffplay
```

## 测试

```powershell
.\.venv\Scripts\python -m pytest
```
