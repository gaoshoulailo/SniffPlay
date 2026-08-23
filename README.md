# SniffPlay

嗅播音乐播放器是一个使用 Python、PySide6 和 QML 构建的轻量 Windows 桌面音乐播放器。它支持搜索 Bilibili 公开音视频资源、播放本地音频，并在本机管理收藏、歌单和播放历史。

## 当前功能

- PySide6 + QML 无边框桌面界面
- Bilibili 公开视频搜索与 DASH 音频播放
- WBI 请求签名、失败重试和封面本地缓存
- 本地 MP3、FLAC、WAV、M4A、AAC、OGG、Opus 等音频文件播放
- 播放、暂停、进度跳转、音量、上一首、下一首和自动续播
- 搜索结果、收藏、歌单和播放历史统一播放队列
- 收藏、取消收藏和收藏列表播放
- 创建、重命名和删除歌单
- 向歌单添加、移除和重新排序歌曲
- 播放全部歌单或从指定歌曲开始播放
- 达到有效播放阈值后记录历史，并支持从历史重新播放
- SQLite 本地持久化
- libmpv 缺失时安全降级，不阻止界面启动
- 可扩展的 Provider、Player 和 Repository 边界

## 当前边界

- Bilibili 数据源只使用公开接口，不包含账号登录或会员资源访问。
- Bilibili 搜索当前读取第一页，分 P 视频播放第一个分 P。
- 临时网络播放地址不会写入数据库，重新播放时会再次解析。
- 本地文件被移动或删除后，对应歌单、收藏或历史记录会提示文件不存在。
- 目前没有歌词、下载、均衡器、播放模式切换、安装包和自动更新。
- 当前主题为固定深色主题，尚未提供运行时主题切换。

## 技术架构

```text
PySide6 / QML
      |
      v
AppController
      |-- SearchService -- ProviderRegistry -- BilibiliDataSource
      |-- Player -------- MpvPlayer / UnavailablePlayer
      `-- Repositories -- SQLAlchemy -- SQLite
```

- QML 只负责展示状态和接收交互。
- `AppController` 是 QML 与 Python 业务层之间的桥梁。
- `SearchService` 聚合音乐来源，并统一解析本地或网络播放资源。
- Provider 隔离特定音乐来源的请求、解析和错误处理。
- Player 抽象隔离 libmpv 实现。
- Repository 管理歌曲、收藏、歌单、播放历史和设置数据。

## 环境要求

- Windows 10/11
- Python 3.12
- uv（推荐）或 pip
- 64 位 libmpv

## 安装与启动

使用 uv：

```powershell
uv sync --extra dev
uv run sniffplay
```

使用 Python 虚拟环境：

```powershell
python -m venv .venv
.\.venv\Scripts\python -m pip install -e ".[dev]"
.\.venv\Scripts\python -m sniffplay
```

安装后也可以使用控制台命令：

```powershell
.\.venv\Scripts\sniffplay
```

从命令行直接打开本地音频：

```powershell
.\.venv\Scripts\sniffplay "D:\Music\example.flac"
```

## libmpv

SniffPlay 使用 libmpv 负责音频解码。在 Windows 开发环境中，将 64 位 `mpv-2.dll` 或 `libmpv-2.dll` 放入 `vendor/mpv`，也可以设置 DLL 的绝对路径：

```powershell
$env:SNIFFPLAY_MPV_DLL = "D:\path\to\mpv-2.dll"
```

没有检测到 libmpv 时，应用仍可搜索和管理本地数据，但播放功能会显示为不可用。

验证 libmpv 加载、解码和播放状态：

```powershell
.\.venv\Scripts\python scripts\verify_mpv.py
```

当前开发机所用构建和校验信息记录在 `vendor/mpv/README.md`。该开发构建使用 GPL 许可证，正式分发前必须补齐许可证与对应源代码提供流程，或更换为经过验证的 LGPL 兼容构建。

开发机基线数据（静音播放、5 秒采样，仅供比较）：

| 状态 | 总 CPU | 工作集 |
| --- | ---: | ---: |
| 应用空闲 | 约 0.02% | 约 123 MB |
| 完整应用播放 | 约 0.20% | 约 129 MB |

## 本地数据

数据库、日志和其他应用数据默认保存在 Windows 用户数据目录。开发时可以指定独立目录：

```powershell
$env:SNIFFPLAY_DATA_DIR = "$PWD\data"
.\.venv\Scripts\python -m sniffplay
```

主要持久化内容包括：

- 标准化歌曲信息
- 收藏
- 歌单及歌曲顺序
- 有效播放历史
- 应用设置

## 测试

运行当前稳定主线测试：

```powershell
.\.venv\Scripts\python -m pytest --ignore=tests/test_settings.py
```

`tests/test_settings.py` 属于尚未完成接线的自定义背景开发分支，目前会在测试收集阶段失败。完成该分支的控制器与应用装配后，应恢复为：

```powershell
.\.venv\Scripts\python -m pytest
```

检查已接入的 QML 页面：

```powershell
.\.venv\Scripts\pyside6-qmllint.exe -I src\sniffplay_ui `
  src\sniffplay_ui\Main.qml `
  src\sniffplay_ui\pages\SearchPage.qml `
  src\sniffplay_ui\pages\FavoritesPage.qml `
  src\sniffplay_ui\pages\PlaylistPage.qml `
  src\sniffplay_ui\pages\HistoryPage.qml `
  src\sniffplay_ui\components\PlayerBar.qml
```

## 扩展音乐来源

新的音乐来源应实现 `MusicProvider`：

```python
class ExampleProvider(MusicProvider):
    id = "example"
    display_name = "Example"

    async def search(self, query: str, limit: int = 30) -> list[Track]:
        ...

    async def resolve_stream(self, track: Track) -> StreamInfo:
        ...
```

实现后在 `src/sniffplay/application.py` 的 `ProviderRegistry` 中注册。Provider 应只返回标准 `Track` 和 `StreamInfo`，不应直接操作 QML、播放器或数据库。

接入第三方音乐来源时，必须遵守目标站点的服务条款、版权要求和访问规则，不应绕过登录、付费或其他访问控制。
