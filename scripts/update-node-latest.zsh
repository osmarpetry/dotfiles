#!/usr/bin/env zsh
set -euo pipefail

export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
export PATH="${ASDF_DATA_DIR}/shims:$PATH"

asdf install nodejs latest
asdf set -u nodejs latest
