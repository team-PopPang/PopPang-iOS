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


def main():
    try:
        payload = json.load(sys.stdin)
        cwd = payload.get("cwd") or os.getcwd()
        root = repo_root(cwd)
        last_message = payload.get("last_assistant_message")
        record = {
            "permission_mode": payload.get("permission_mode"),
            "ts": utc_now(),
            "event": payload.get("hook_event_name", "Stop"),
            "session_id": payload.get("session_id"),
            "turn_id": payload.get("turn_id"),
            "cwd": cwd,
            "model": payload.get("model"),
            "stop_hook_active": payload.get("stop_hook_active"),
            "last_assistant_message_length": len(last_message) if isinstance(last_message, str) else None,
        }
        append_jsonl(root, "turns.jsonl", record)
    except Exception:
        pass

    print(json.dumps({"continue": True}, separators=(",", ":")))


if __name__ == "__main__":
    main()
