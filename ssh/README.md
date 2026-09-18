# ssh

What's committed here: `config`, `allowed_signers`, `*.pub`. **Never** a
private key, not even encrypted — that's a deliberate decision (see
`docs/PLAN.md` section 2), matching how caarlos0 and ThePrimeagen both do it.

## Moving to a new machine

1. Copy your private keys in by hand — password manager, AirDrop, or a
   temporary HTTPS token to clone this repo the first time (the bootstrap
   paradox: cloning a private repo over SSH needs a key that lives outside
   the repo by design, so the very first one always arrives out of band).
   Land it at `~/.ssh/id_ed25519`, mode `0600`.
2. Run `./setup.sh` — `link.sh` symlinks `config`, `allowed_signers`, and the
   `.pub` file into `~/.ssh/`.
3. `ssh -T git@github.com` to confirm.

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
