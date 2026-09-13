#!/usr/bin/env python3
from __future__ import annotations

import plistlib
import sys
from pathlib import Path


def rewrite_home(value, home: str):
    old_home = "/Users/osmarpetry"
    if isinstance(value, str):
        return value.replace(old_home, home)
    if isinstance(value, list):
        return [rewrite_home(item, home) for item in value]
    if isinstance(value, dict):
        return {key: rewrite_home(item, home) for key, item in value.items()}
    return value


def main() -> int:
    source = Path(sys.argv[1])
    home = sys.argv[2]
    target = Path(home) / "Library/Preferences/com.lowtechguys.Clop.plist"
    target.parent.mkdir(parents=True, exist_ok=True)

    with source.open("rb") as handle:
        selected = plistlib.load(handle)

    selected = {key: rewrite_home(value, home) for key, value in selected.items()}

    existing = {}
    if target.exists():
        with target.open("rb") as handle:
            existing = plistlib.load(handle)

    existing.update(selected)
    with target.open("wb") as handle:
        plistlib.dump(existing, handle)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

