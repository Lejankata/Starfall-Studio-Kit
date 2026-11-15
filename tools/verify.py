#!/usr/bin/env python3
"""Static repository checks only. Not a Luau compiler or Roblox runtime test."""
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = [
    "src/server/StarfallServer.server.luau",
    "src/client/StarfallClient.client.luau",
    "default.project.json",
    "docs/TESTING.md",
    "docs/ARCHITECTURE.md",
    "docs/V2_UPGRADE.md",
    "docs/SECURITY.md",
    "LICENSE",
    "README.md",
]


def validate():
    errors = []
    for name in REQUIRED:
        if not (ROOT / name).is_file():
            errors.append(f"Missing: {name}")
    if errors:
        return errors

    with (ROOT / "default.project.json").open(encoding="utf-8") as stream:
        project = json.load(stream)
    tree = project.get("tree", {})
    if tree.get("$className") != "DataModel":
        errors.append("Rojo root must be DataModel")
    server_path = tree.get("ServerScriptService", {}).get("StarfallServer", {}).get("$path")
    client_path = tree.get("StarterPlayer", {}).get("StarterPlayerScripts", {}).get("StarfallClient", {}).get("$path")
    if server_path != REQUIRED[0]:
        errors.append("Rojo server path incorrect")
    if client_path != REQUIRED[1]:
        errors.append("Rojo client path incorrect")
    for path in (server_path, client_path):
        if not path or not (ROOT / path).is_file():
            errors.append(f"Rojo source path missing: {path}")

    server = (ROOT / REQUIRED[0]).read_text(encoding="utf-8")
    client = (ROOT / REQUIRED[1]).read_text(encoding="utf-8")
    for feature in (
        "GetDataStore", "UpdateAsync", "GetAsync", "pcall",
        "ProximityPrompt", "Triggered:Connect", "Magnitude",
        "OnServerEvent", '"buy"', '"quest"', '"daily"',
        "Quest", "StarfallWorld", "BindToClose", "PlayerRemoving",
    ):
        if feature not in server:
            errors.append(f"Server missing expected feature marker: {feature}")
    for feature in (
        "OnClientEvent", "FireServer", "ScrollingFrame", "ViewportSize",
        '"Shop"', '"Quests"', '"Daily"', "StarfallHUD",
    ):
        if feature not in client:
            errors.append(f"Client missing expected feature marker: {feature}")
    if 'StarfallNetwork' not in server or 'StarfallNetwork' not in client:
        errors.append("Client/server network name mismatch")
    return errors


if __name__ == "__main__":
    problems = validate()
    if problems:
        for problem in problems:
            print(f"FAIL: {problem}", file=sys.stderr)
        raise SystemExit(1)
    print("PASS: Structural and source-contract checks. Studio gameplay is not tested.")
