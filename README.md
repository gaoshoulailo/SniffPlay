# SniffPlay

<p align="center">
  <img src="assets/sniffplay-icon.png" width="128" height="128" alt="SniffPlay 图标">
</p>

<p align="center">
  <a href="https://github.com/gaoshoulailo/SniffPlay/actions/workflows/test.yml"><img src="https://github.com/gaoshoulailo/SniffPlay/actions/workflows/test.yml/badge.svg" alt="自动测试"></a>
  <a href="https://github.com/gaoshoulailo/SniffPlay/actions/workflows/build-windows.yml"><img src="https://github.com/gaoshoulailo/SniffPlay/actions/workflows/build-windows.yml/badge.svg" alt="Windows 自动构建"></a>
</p>

嗅播音乐播放器是一个使用 Python、PySide6 和 QML 构建的轻量 Windows 桌面音乐播放器。它支持搜索 Bilibili 公开音视频资源、播放本地音频，并在本机管理收藏、歌单和播放历史。

## 当前功能

- PySide6 + QML 无边框桌面界面
- Bilibili 公开视频搜索与 DASH 音频播放
- WBI 请求签名、失败重试和封面本地缓存
- 本地 MP3、FLAC、WAV、M4A、AAC、OGG、Opus 等音频文件播放
- 播放、暂停、进度跳转、音量、上一首、下一首和自动续播
- 顺序播放、单曲循环和随机播放模式
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
- 目前没有歌词、下载、均衡器、安装包和自动更新。
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

创建可双击启动的 Windows 快捷方式：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\create_shortcut.ps1
```

该命令会在项目根目录和当前用户桌面生成 `SniffPlay.lnk`，并通过
`pythonw.exe` 无控制台启动应用。默认使用 `02` 号薄荷高亮图标，也可以选择
`01` 到 `06` 号快捷方式图标，例如：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\create_shortcut.ps1 -IconVariant 06
```

项目目录移动后，需要重新运行该脚本以更新快捷方式中的绝对路径。

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

数据库、日志和封面缓存默认保存在稳定的便携数据目录，不再依赖启动时的工作目录，也不会写入 Windows 用户数据目录：

- 源码运行：项目根目录下的 `data`
- 打包运行：`SniffPlay.exe` 所在目录下的 `data`
- 自定义位置：优先使用 `SNIFFPLAY_DATA_DIR`

```text
data/
├── sniffplay.db
├── logs/sniffplay.log
└── cache/covers/bilibili/*.jpg
```

仍可通过环境变量指定其他位置：

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
- Bilibili 音频封面缓存

旧版本位于 Windows 用户目录的数据不会被自动删除。确认本地 `data` 目录运行正常后，可自行清理旧目录以释放 C 盘空间。

## Windows 本地打包

先确认 `.venv` 已安装开发依赖，并将 64 位 `libmpv-2.dll` 放在 `vendor/mpv`，然后运行：

```powershell
.\scripts\build_windows.ps1
```

脚本会先运行测试，再通过 PyInstaller 生成 one-folder 便携目录并执行启动烟雾测试：

```text
dist/SniffPlay/
├── SniffPlay.exe
├── _internal/
├── data/
├── licenses/libmpv-README.md
└── README.md
```

个人数据库、日志和封面缓存不会进入构建产物。当前本机使用的 libmpv 构建采用 GPL-2.0-or-later，`vendor/mpv/README.md` 记录了版本和校验值；对外发布前仍需完成对应许可证及源码提供流程，或改用经过验证的 LGPL 兼容构建。

## 测试

运行完整测试：

```powershell
.\.venv\Scripts\python -m pytest
```

检查 Python 文件能否正常编译：

```powershell
.\.venv\Scripts\python -m compileall -q src tests
```

检查已接入的 QML 页面：

```powershell
.\.venv\Scripts\pyside6-qmllint.exe -I src\sniffplay_ui `
  src\sniffplay_ui\Main.qml `
  src\sniffplay_ui\components\AppButton.qml `
  src\sniffplay_ui\components\ContextMenuItem.qml `
  src\sniffplay_ui\components\NavButton.qml `
  src\sniffplay_ui\components\PlayerBar.qml `
  src\sniffplay_ui\pages\SearchPage.qml `
  src\sniffplay_ui\pages\FavoritesPage.qml `
  src\sniffplay_ui\pages\NowPlayingPage.qml `
  src\sniffplay_ui\pages\PlaylistPage.qml `
  src\sniffplay_ui\pages\HistoryPage.qml
```

`.github/workflows/test.yml` 会在推送 `main`、提交到 `main` 的 Pull Request 以及手动触发时，在 GitHub 的 Windows 环境中按 `uv.lock` 执行以上检查。此流程只负责测试，不构建或上传发布包。

## GitHub Windows 自动构建

`.github/workflows/build-windows.yml` 会在推送 `main` 或手动触发时执行：

1. 按 `uv.lock` 安装 Python 3.12 依赖。
2. 下载固定版本的 libmpv，同时校验归档和 DLL 的 SHA-256。
3. 调用 `scripts/build_windows.ps1` 运行测试、打包和启动烟雾测试。
4. 从仓库预置文件复制 GPL-2.0 许可证文本，生成 `SniffPlay-Windows-x64.zip` 和 SHA-256 文件。
5. 上传保留 14 天的 GitHub Actions Artifact。

普通 `main` 分支构建只生成 Artifact。推送与 `pyproject.toml` 版本一致的标签（例如当前版本 `v0.1.3`）时，工作流会在构建成功后创建草稿 Release，并附上 ZIP、SHA-256 和自动生成的更新说明：

```powershell
git tag v0.1.3
git push origin v0.1.3
```

草稿 Release 不会直接对外公开。正式公开前必须确认项目许可证，并完成 libmpv 对应源码提供流程，或切换到经过验证的 LGPL 兼容构建；检查无误后再到 GitHub Release 页面手动发布草稿。

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
