# Machine export

One archive to move to a new machine (or keep as a portable backup): the
`~/workspace` repos minus `node_modules` (so uncommitted/unpushed local
state survives — a fresh `git clone` from `manifests/repos.json` loses
that), the SSH files that never live in this repo (`ssh/README.md`'s
"never a private key" rule means they're the one thing cloning dotfiles
doesn't restore), and Claude's auto-memory
(`~/.claude/projects/*/memory/`, outside any repo).

The archive is passphrase-encrypted with 7z (`p7zip`, already in the
Brewfile) — it carries a private SSH key in cleartext once decrypted, so it
must never be committed and should live only in your own cold storage.

## Old machine: export

7z has no terminal to prompt on when it's run through Claude's Bash tool,
so the passphrase has to come from an environment variable set in your own
shell *before* you open or continue the Claude Code session — env vars set
that way are inherited by the session's tool calls, and this keeps the
passphrase out of the prompt text and out of shell history.

```sh
export EXPORT_PASSPHRASE='pick something long'
```

Then paste this into Claude Code:

```
Run ./scripts/export_machine_bootstrap.zsh --apply
```

It writes `~/workspace/backups/machine-export-<date>.7z`. Copy that file to
the new machine by hand (AirDrop, a USB drive, your own cold storage — not
this repo, not a chat upload).

## New machine: import

No Claude Code is set up yet at this point, so this is a plain terminal
command, not a Claude prompt:

```sh
export EXPORT_PASSPHRASE='the same passphrase'
./scripts/import_machine_bootstrap.zsh /path/to/machine-export-<date>.7z
```

This only works if `import_machine_bootstrap.zsh` itself is already on the
new machine — clone this repo (or just copy that one script over) before
running it.

It restores `~/workspace/`, drops the SSH files into `~/.ssh/` (private
keys at `0600`), and restores each Claude memory directory under
`~/.claude/projects/`.

**Caveat**: Claude memory directories are keyed by absolute project path
(e.g. `~/.claude/projects/-Users-osmar-dotfiles`). Restoring them only
lands in the right place if the new machine reuses the same `$HOME`
username as the old one — true for a personal-machine move, worth
double-checking otherwise.

**Caveat**: any symlink inside a workspace repo (not `~/.ssh`, which is
handled separately) gets archived as a plain file containing the link's
target path rather than a real symlink or its content — p7zip 17.05 has no
dereference-on-add flag. A git-tracked symlink shows up as modified after
restore; `git checkout -- <path>` fixes it.
