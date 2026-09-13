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
