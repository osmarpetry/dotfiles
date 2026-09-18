# git

`gitconfig` symlinks to `~/.gitconfig`. Personal identity (osmarpetry@gmail.com, `id_ed25519`) is the default `[user]` block — that's correct for every repo this machine tracks today.

SSH commit signing is on by default (`gpg.format = ssh`, signed with `id_ed25519`, verified against `ssh/allowed_signers`).

`hooks/pre-commit` runs `gitleaks git --staged` and blocks a commit that stages a secret. `./setup.sh` points `core.hooksPath` at `git/hooks`, but only in this repo's own `.git/config` — not via the globally-symlinked `gitconfig` above, so no other repo on the machine picks it up. A fresh clone has no hook until `./setup.sh` runs once.
