# binary-apps

Apps with no Homebrew (or nix) package. No zip backups here — `install-optional.sh`
just opens the download page for anything with a known URL, so you grab a
current build instead of a stale one. Install is a manual drag-to-Applications
after that; not worth scripting `.dmg` mounting for a handful of apps.

| App | Status |
|---|---|
| Dropover | no cask — https://dropoverapp.com |
| Supercharge | no cask, exact app identity unconfirmed — no reliable URL, install manually |
| Microsoft To Do | no cask — Mac App Store only, no direct URL to open |
| Hand Mirror | no cask found under any tried name — no reliable URL, install manually |
| Qwen | no cask (only an unrelated `qwen-code` CLI formula) — https://chat.qwen.ai |
| IRPF2026 | Brazilian Receita Federal tax software, no cask by design, updates yearly — get the current year's link directly from gov.br each year, don't hardcode one here |

`RealTimeSync.app` needs no entry — it ships bundled inside FreeFileSync.

`install-optional.sh` runs `open <url>` for every entry with a known URL
above. Entries with no reliable URL just print a reminder to install by hand.
