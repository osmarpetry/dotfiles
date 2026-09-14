# ssh

What's committed here: `config`, `allowed_signers`, `*.pub`. **Never** a
private key, not even encrypted — that's a deliberate decision (see
`docs/PLAN.md` section 2), matching how caarlos0 and ThePrimeagen both do it.

## Moving to a new machine

1. Copy your private keys in by hand — password manager, AirDrop, or a
   temporary HTTPS token to clone this repo the first time (the bootstrap
   paradox: cloning a private repo over SSH needs a key that lives outside
   the repo by design, so the very first one always arrives out of band).
   Land them at `~/.ssh/id_ed25519` and `~/.ssh/tempo_id_rsa`, mode `0600`.
2. Run `./setup.sh` — `link.sh` symlinks `config`, `allowed_signers`, and both
   `.pub` files into `~/.ssh/`.
3. `ssh -T git@github.com` to confirm.

## Personal vs. work identity

`config` defines two Host aliases:

```
Host github-personal   -> ~/.ssh/id_ed25519
Host github-work       -> ~/.ssh/tempo_id_rsa
```

Today almost everything (68 of 70 tracked repos) is under the `osmarpetry`
personal account, and `tempo_id_rsa` is actually used for SSH access into
tempo.build's canvas dev sandboxes, not for cloning a separate work org.
So in practice: nothing needs the `github-work` alias yet for cloning — it's
here, ready, for whenever a repo needs the work key instead of the personal
one. When that happens:

- Clone it with the aliased remote: `git@github-work:org/repo.git`.
- Add a matching git identity override — see `git/README.md` for the
  `includeIf gitdir:` mechanism. `git/gitconfig-work.example` shows the shape.

Don't force-restructure the existing 68 personal repos into a `personal/`
subtree to "match" this scheme — they're already fine where they are
(`~/workspace/<owner>/<repo>`, driven by `manifests/repos.json`). This split
exists for the next repo that actually needs it, not retroactively.

**Same shape as asdf, if that mental model already clicks**: asdf has a
global default (`~/.tool-versions`) and a local override (a project's own
`.tool-versions`, only when that project needs a different version). SSH
identity here works the same way — `id_ed25519` is the global default
everywhere, `github-work`/`tempo_id_rsa` is the local override, active only
under `~/workspace/work/**`. Nothing project-specific means the global
default applies, exactly like asdf falling through to `~/.tool-versions`
when a project has no local one.

## Commit signing

`allowed_signers` holds the public key used to verify your own commit
signatures. `git/gitconfig` wires it up:

```ini
[gpg]
	format = ssh
[gpg "ssh"]
	allowedSignersFile = ~/.ssh/allowed_signers
[commit]
	gpgSign = true
```

## Machine-local additions

`config`'s first line is `Include ~/dotfiles/local/ssh-config` — anything
machine-specific that shouldn't be committed goes there. `link.sh` creates it
empty if missing, so the Include never errors on a fresh machine.
