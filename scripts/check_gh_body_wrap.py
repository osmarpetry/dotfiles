#!/usr/bin/env python3
"""PreToolUse hook: block a `gh pr|issue|release create|edit|comment` whose
--body/--body-file is hard-wrapped prose (see AGENTS.md §Style and
check_prose_wrap.zsh).

Reads a Claude Code PreToolUse hook payload on stdin, extracts the gh
command's body text, and on a violation prints a deny decision as JSON.
Silent, exit 0, on anything that doesn't apply — a non-gh command, no body,
or a clean body.

Shell-quote parsing needs a real tokenizer, not sed/awk line-by-line
matching (a multi-line --body value breaks line-based regex outright) — the
stdlib's shlex is that tokenizer, which is the one thing here that doesn't
fit the rest of this repo's zsh convention.
"""
import json
import os
import re
import shlex
import subprocess
import sys

GH_BODY_CMD = re.compile(r"\bgh\s+(pr|issue|release)\s+(create|edit|comment)\b")
CHECKER = os.path.expanduser("~/dotfiles/scripts/check_prose_wrap.zsh")


def extract_body(cmd: str) -> str | None:
    if not GH_BODY_CMD.search(cmd):
        return None

    try:
        tokens = shlex.split(cmd, posix=True)
    except ValueError:
        return None  # unbalanced quotes — bail rather than guess

    body = None
    body_file = None
    for i, tok in enumerate(tokens):
        if tok == "--body" and i + 1 < len(tokens):
            body = tokens[i + 1]
        elif tok.startswith("--body="):
            body = tok[len("--body="):]
        elif tok == "--body-file" and i + 1 < len(tokens):
            body_file = tokens[i + 1]
        elif tok.startswith("--body-file="):
            body_file = tok[len("--body-file="):]

    if body_file and body_file != "-" and os.path.isfile(body_file):
        return open(body_file).read()
    return body


def main() -> int:
    data = json.load(sys.stdin)
    cmd = data.get("tool_input", {}).get("command", "") or ""

    text = extract_body(cmd)
    if not text:
        return 0

    result = subprocess.run(
        [CHECKER, "-"], input=text, capture_output=True, text=True
    )
    if result.returncode != 0:
        reason = result.stdout.strip()
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        }))
    return 0


if __name__ == "__main__":
    sys.exit(main())
