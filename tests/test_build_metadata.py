import json
import os
from pathlib import Path
import runpy
import subprocess
import sys

import pytest


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "build_metadata.py"
build_metadata = runpy.run_path(str(SCRIPT))["build_metadata"]


@pytest.fixture
def environment():
    return {
        "GITHUB_SHA": "abcdef0" + "1" * 33,
        "GITHUB_RUN_ID": "12345",
        "GITHUB_RUN_NUMBER": "42",
        "GITHUB_RUN_ATTEMPT": "1",
        "GITHUB_REF": "refs/heads/main",
        "GITHUB_EVENT_NAME": "push",
        "GITHUB_REPOSITORY": "example/SniffPlay",
    }


def test_main_push_generates_traceable_preview(environment):
    metadata = build_metadata("1.2", environment)
    assert metadata["channel"] == "preview"
    assert metadata["release_tag"] == "build-42.1-abcdef0"
    assert metadata["zip_name"] == "SniffPlay-Windows-x64-build-42.1-abcdef0.zip"
    assert metadata["commit"] == environment["GITHUB_SHA"]
    assert metadata["run_url"] == "https://github.com/example/SniffPlay/actions/runs/12345"
    assert metadata["built_at_utc"].endswith("+00:00")


def test_reruns_have_distinct_previews_and_artifacts(environment):
    first = build_metadata("1.2", environment)
    environment["GITHUB_RUN_ATTEMPT"] = "2"
    second = build_metadata("1.2", environment)
    assert first["release_tag"] != second["release_tag"]
    assert first["artifact_name"] != second["artifact_name"]


@pytest.mark.parametrize("version", ["1.2", "1.2.1"])
def test_matching_tag_generates_stable_release(environment, version):
    environment["GITHUB_REF"] = f"refs/tags/v{version}"
    metadata = build_metadata(version, environment)
    assert metadata["channel"] == "stable"
    assert metadata["release_tag"] == f"v{version}"
    assert metadata["zip_name"] == f"SniffPlay-Windows-x64-v{version}.zip"


def test_mismatched_version_blocks_release(environment):
    environment["GITHUB_REF"] = "refs/tags/v1.2.1"
    with pytest.raises(ValueError, match="must match"):
        build_metadata("1.2", environment)


def test_prerelease_version_cannot_be_published_as_stable(environment):
    environment["GITHUB_REF"] = "refs/tags/v1.3rc1"
    with pytest.raises(ValueError, match="must be numeric"):
        build_metadata("1.3rc1", environment)


@pytest.mark.parametrize("reference", ["refs/heads/main", "refs/tags/v1.2", "refs/heads/feature"])
def test_manual_runs_never_publish(environment, reference):
    environment.update(GITHUB_REF=reference, GITHUB_EVENT_NAME="workflow_dispatch")
    metadata = build_metadata("1.2", environment)
    assert metadata["channel"] == "manual"
    assert metadata["release_tag"] == ""


@pytest.mark.parametrize("name", ["GITHUB_SHA", "GITHUB_RUN_NUMBER", "GITHUB_RUN_ATTEMPT"])
def test_invalid_identity_is_rejected(environment, name):
    environment[name] = "invalid\nrelease_tag=unexpected"
    with pytest.raises(ValueError):
        build_metadata("1.2", environment)


def test_cli_writes_metadata_and_action_outputs(tmp_path, environment):
    project = tmp_path / "pyproject.toml"
    project.write_text('[project]\nversion = "1.2"\n', encoding="utf-8")
    output = tmp_path / "outputs.txt"
    destination = tmp_path / "metadata"
    subprocess.run(
        [sys.executable, str(SCRIPT), "--project", str(project), "--output-dir", str(destination)],
        env={**os.environ, **environment, "GITHUB_OUTPUT": str(output)},
        check=True,
    )
    metadata = json.loads((destination / "build-info.json").read_text(encoding="utf-8"))
    assert metadata["channel"] == "preview"
    assert output.read_text(encoding="utf-8").splitlines() == [
        "channel=preview",
        "release_tag=build-42.1-abcdef0",
        "zip_name=SniffPlay-Windows-x64-build-42.1-abcdef0.zip",
        "artifact_name=SniffPlay-Windows-x64-12345-1",
    ]
