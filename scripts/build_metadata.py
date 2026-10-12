from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import tomllib


def build_metadata(version: str, environment: dict[str, str]) -> dict[str, str]:
    commit = environment["GITHUB_SHA"]
    run_id = environment["GITHUB_RUN_ID"]
    run_number = environment["GITHUB_RUN_NUMBER"]
    attempt = environment["GITHUB_RUN_ATTEMPT"]
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise ValueError("Invalid commit SHA")
    if not all(value.isdigit() for value in (run_id, run_number, attempt)):
        raise ValueError("Invalid workflow run identity")
    reference = environment["GITHUB_REF"]
    event = environment["GITHUB_EVENT_NAME"]
    channel = "manual"
    release_tag = ""
    build_id = f"build-{run_number}.{attempt}-{commit[:7]}"
    if event == "push" and reference == "refs/heads/main":
        channel = "preview"
        release_tag = build_id
    elif event == "push" and reference.startswith("refs/tags/v"):
        if not re.fullmatch(r"\d+\.\d+(?:\.\d+)?", version):
            raise ValueError("Stable release version must be numeric, for example 1.2.1")
        release_tag = reference.removeprefix("refs/tags/")
        if release_tag != f"v{version}":
            raise ValueError(f"Release tag must match pyproject.toml: expected v{version}")
        channel = "stable"
        build_id = release_tag
    server = environment.get("GITHUB_SERVER_URL", "https://github.com")
    return {
        "version": version,
        "channel": channel,
        "build_id": build_id,
        "release_tag": release_tag,
        "commit": commit,
        "ref": reference,
        "run_id": run_id,
        "run_number": run_number,
        "run_attempt": attempt,
        "run_url": f"{server}/{environment['GITHUB_REPOSITORY']}/actions/runs/{run_id}",
        "built_at_utc": datetime.now(timezone.utc).isoformat(),
        "zip_name": f"SniffPlay-Windows-x64-{build_id}.zip",
        "artifact_name": f"SniffPlay-Windows-x64-{run_id}-{attempt}",
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", type=Path, default=Path("pyproject.toml"))
    parser.add_argument("--output-dir", type=Path, default=Path("build-metadata"))
    arguments = parser.parse_args()
    with arguments.project.open("rb") as project_file:
        version = tomllib.load(project_file)["project"]["version"]
    metadata = build_metadata(version, dict(os.environ))
    arguments.output_dir.mkdir(parents=True, exist_ok=True)
    (arguments.output_dir / "build-info.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    if output_path := os.environ.get("GITHUB_OUTPUT"):
        with Path(output_path).open("a", encoding="utf-8") as output:
            for name in ("channel", "release_tag", "zip_name", "artifact_name"):
                output.write(f"{name}={metadata[name]}\n")


if __name__ == "__main__":
    main()
