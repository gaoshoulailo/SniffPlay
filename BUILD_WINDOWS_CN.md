# SniffPlay Windows 构建指南

本文说明如何在本地构建 SniffPlay Windows x64 版本，以及如何通过 GitHub Actions 创建版本构建。

## 环境要求

- Windows 10 或 Windows 11
- Python 3.12
- 已安装 Git
- 项目根目录存在 `.venv`

首次准备开发环境：

```powershell
uv sync --locked --extra dev
```

如果没有 uv，也可以使用虚拟环境：

```powershell
python -m venv .venv
.\.venv\Scripts\python -m pip install -e ".[dev]"
```

## 本地构建

构建脚本会执行测试、PyInstaller 打包和启动烟雾测试：

```powershell
.\scripts\build_windows.ps1
```

跳过测试：

```powershell
.\scripts\build_windows.ps1 -SkipTests
```

跳过启动烟雾测试：

```powershell
.\scripts\build_windows.ps1 -SkipSmokeTest
```

构建结果位于：

```text
dist/SniffPlay/
├─ SniffPlay.exe
├─ _internal/
├─ data/
├─ licenses/
└─ README.md
```

构建前必须准备 `vendor/mpv/libmpv-2.dll`。GitHub Actions 会自动下载并校验该文件；本地构建可从项目约定的 libmpv 归档中放入该路径。

## 推送后自动构建与发布

仓库需启用 GitHub Actions，并允许发布任务使用 `GITHUB_TOKEN` 的 `contents: write` 权限；工作流已仅对发布任务配置写权限，构建任务保持只读。无需额外配置个人访问令牌。

| 触发方式 | 成功后的行为 |
| --- | --- |
| 推送 `main` | 自动公开发布 Pre-release，不设为 Latest |
| 推送与项目版本一致的 `v*` 标签 | 自动公开发布正式 Release，设为 Latest |
| Actions 页面手动运行 | 只生成 Artifact，不发布 Release |

预览版标签为 `build-<运行编号>.<重试次数>-<提交短哈希>`，例如 `build-42.1-abcdef0`。每次运行使用独立版本，不覆盖旧预览版，重新运行也不会重用之前的预览版标签。预览标签不以 `v` 开头，不属于正式版构建触发范围。

ZIP 名称包含构建标识，如 `SniffPlay-Windows-x64-build-42.1-abcdef0.zip` 或 `SniffPlay-Windows-x64-v1.2.1.zip`。ZIP 内和 Release 附件均提供 `build-info.json`，包含项目版本、渠道、完整提交哈希、构建时间（UTC）、运行编号和运行链接。源码提交标识对应本次检出的代码，不是发布时重新读取的 main 分支。

Artifact 保留 14 天；此期限不应用于 Release 附件。当前不自动清理旧预览版，也不会删除正式版或 libmpv 依赖归档。手动构建可在 Actions 运行详情页下载 Artifact。

## 发布正式版本

### 1. 更新版本号

修改 `pyproject.toml`：

```toml
version = "1.2.1"
```

版本号修改后必须同步锁文件，并确认锁定安装可以成功：

```powershell
uv lock
uv sync --locked --extra dev
```

提交时要同时包含 `pyproject.toml` 和 `uv.lock`。否则 GitHub Actions 的 `uv sync --locked` 会因锁文件过期而失败。

版本号必须与 Git 标签一致。例如 `1.2.1` 对应 `v1.2.1`。正式版本支持两段或三段数字（如 `1.2`、`1.2.1`），开发预览请通过 main 推送发布，而不是使用 `v1.3rc1` 一类标签。

### 2. 提交并推送代码

```powershell
git add pyproject.toml uv.lock
git commit -m "发布 v1.2.1"
git push origin main
```

### 3. 创建并推送版本标签

```powershell
git tag -a v1.2.1 -m "SniffPlay v1.2.1"
git push origin v1.2.1
```

推送标签后，`.github/workflows/build-windows.yml` 会自动：

1. 安装 Python 3.12 和锁定的项目依赖。
2. 下载并校验 libmpv。
3. 执行测试、打包和启动烟雾测试。
4. 生成带版本标识的 ZIP、SHA-256 和构建信息文件。
5. 自动公开发布正式 Release，无需手动发布草稿。

发布前请审查代码和版本号；推送正式标签即表示允许公开发布。已存在的 Release 不会被自动覆盖：如果正式版本已经成功发布，请使用新的版本号。若发布任务异常中断并留下不完整 Release，应先检查远端状态，人工处理后再重试，工作流不会自动删除它。

## 检查构建结果

在 GitHub 仓库的 **Actions** 页面查看构建日志和 Artifact，在 **Releases** 页面下载预览版或正式版。所有发布都依赖同一次运行中的测试、打包和启动烟雾测试成功。任意检查失败时不发布，不使用跳过测试参数，也不影响之前成功发布的版本。

本流程只负责构建与发布，不包含客户端内自动检查更新或下载安装。

## 常见问题

### 标签版本不匹配

工作流要求：

```text
pyproject.toml version = 1.2.1
Git tag = v1.2.1
```

如果不一致，标签构建会在版本校验步骤失败。

### 本地找不到 libmpv

确认文件存在：

```text
vendor/mpv/libmpv-2.dll
```

也可以设置环境变量指定 DLL 路径后运行验证脚本：

```powershell
$env:SNIFFPLAY_MPV_DLL = "D:\path\to\libmpv-2.dll"
.\.venv\Scripts\python scripts\verify_mpv.py
```

### 只想验证代码

```powershell
.\.venv\Scripts\python -m pytest
.\.venv\Scripts\python -m compileall -q src tests
```
