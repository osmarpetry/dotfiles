# git

`gitconfig` symlinks to `~/.gitconfig`. Personal identity (osmarpetry@gmail.com,
`id_ed25519`) is the default `[user]` block — that's correct for 68 of 70
repos this machine tracks today.

Work identity is an override, not the default: anything cloned under
`~/workspace/work/**` picks up `~/.gitconfig-work` instead, via:

```ini
[includeIf "gitdir:~/workspace/work/**"]
	path = ~/.gitconfig-work
```

`gitconfig-work.example` shows the shape. Copy it to `~/.gitconfig-work` by
hand (not templated/symlinked — it holds a real name/email pair) when a work
repo actually shows up. See `ssh/README.md` for the matching SSH side
(`github-work` Host alias, `tempo_id_rsa`).

SSH commit signing is on by default (`gpg.format = ssh`, signed with
`id_ed25519`, verified against `ssh/allowed_signers`).

`hooks/pre-commit` runs `gitleaks git --staged` and blocks a commit that
stages a secret. `./setup.sh` points `core.hooksPath` at `git/hooks`, but
only in this repo's own `.git/config` — not via the globally-symlinked
`gitconfig` above, so no other repo on the machine picks it up. A fresh
clone has no hook until `./setup.sh` runs once.

**Same shape as asdf**: global default (`~/.tool-versions`) + local override
(a project's own `.tool-versions`). Here, the base `[user]` block is the
global default and `includeIf gitdir:~/workspace/work/**` is the local
override — a repo outside that path just falls through to the global
identity, same as asdf falling through when there's no local pin.
