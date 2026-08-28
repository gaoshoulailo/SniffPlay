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

## 发布新版本

### 1. 更新版本号

修改 `pyproject.toml`：

```toml
version = "0.1.4"
```

版本号修改后必须同步锁文件，并确认锁定安装可以成功：

```powershell
.\.venv\Scripts\uv.exe lock
.\.venv\Scripts\uv.exe sync --locked --extra dev
```

提交时要同时包含 `pyproject.toml` 和 `uv.lock`。否则 GitHub Actions 的 `uv sync --locked` 会因锁文件过期而失败。

版本号必须与 Git 标签一致。例如 `0.1.4` 对应 `v0.1.4`。

### 2. 提交并推送代码

```powershell
git add pyproject.toml BUILD_WINDOWS_CN.md
git commit -m "发布 v0.1.4"
git push origin main
```

### 3. 创建并推送版本标签

```powershell
git tag -a v0.1.4 -m "SniffPlay v0.1.4"
git push origin v0.1.4
```

推送标签后，`.github/workflows/build-windows.yml` 会自动：

1. 安装 Python 3.12 和锁定的项目依赖。
2. 下载并校验 libmpv。
3. 执行测试、打包和启动烟雾测试。
4. 生成 `SniffPlay-Windows-x64.zip` 和 SHA-256 文件。
5. 创建 GitHub 草稿 Release。

## 检查构建结果

在 GitHub 仓库的 **Actions** 页面查看构建日志和 Artifact。标签构建成功后，在 **Releases** 页面检查草稿 Release，确认 ZIP、SHA-256 和许可证文件无误，再手动发布 Release。

## 常见问题

### 标签版本不匹配

工作流要求：

```text
pyproject.toml version = 0.1.4
Git tag = v0.1.4
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
