#!/usr/bin/env python3
import datetime
import json
import os
import subprocess
import sys


def utc_now():
    return datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z")


def repo_root(cwd):
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=cwd,
            check=True,
            capture_output=True,
            text=True,
        )
        return result.stdout.strip()
    except Exception:
        return cwd


def append_jsonl(root, filename, record):
    log_dir = os.path.join(root, ".codex", "logs")
    os.makedirs(log_dir, exist_ok=True)
    path = os.path.join(log_dir, filename)
    with open(path, "a", encoding="utf-8") as file:
        file.write(json.dumps(record, ensure_ascii=False, separators=(",", ":")) + "\n")


def command_from_tool_input(tool_input):
    if isinstance(tool_input, dict):
        command = tool_input.get("command")
        if isinstance(command, str):
            return command
    return None


def main():
    try:
        payload = json.load(sys.stdin)
        cwd = payload.get("cwd") or os.getcwd()
        root = repo_root(cwd)
        tool_input = payload.get("tool_input")
        record = {
            "command": command_from_tool_input(tool_input),
            "permission_mode": payload.get("permission_mode"),
            "ts": utc_now(),
            "event": payload.get("hook_event_name", "PreToolUse"),
            "session_id": payload.get("session_id"),
            "turn_id": payload.get("turn_id"),
            "cwd": cwd,
            "model": payload.get("model"),
            "tool_name": payload.get("tool_name"),
            "tool_use_id": payload.get("tool_use_id"),
        }
        append_jsonl(root, "tools.jsonl", record)
    except Exception:
        pass


if __name__ == "__main__":
    main()
