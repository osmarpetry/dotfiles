# hammerspoon

Scoped to exactly two things, not general window management:

- **`mic-pin.lua`** — forces the built-in mic (`MacBook Pro Microphone` /
  `MacBook Air Microphone`) as default input whenever a Bluetooth/USB device
  tries to steal it. Reactive via `hs.audiodevice.watcher`, plus a manual
  `cmd+alt+ctrl+I` hotkey. This is the exact script already running on this
  machine, just vendored — not a rewrite.
- **`meeting-reminder.lua`** — polls Calendar every 60s via `icalBuddy`
  (`brew "ical-buddy"`), notifies 5 min before a meeting, opens its URL in
  the default browser at start time. Dedup is in-memory, keyed by
  `title|startTime`, cleared on Hammerspoon reload.

`init.lua` just installs the `hs` CLI and requires both modules.

## One-time manual step

Grant Hammerspoon **Accessibility** and **Calendar** permissions in
System Settings → Privacy & Security — Hammerspoon will prompt for these on
first run of each script; without Calendar access `icalBuddy` returns
"No calendars" and the reminder silently does nothing.

## Known limitation

`meeting-reminder.lua`'s icalBuddy output parsing hasn't been verified
against a real populated calendar yet (Calendar access wasn't granted when
this was written) — it parses defensively (regex over the whole event block
for a date/time/URL, not exact property-line positions), but if `icalBuddy`'s
actual output shape differs, the fix is entirely inside `parseBlock()` in
`meeting-reminder.lua`.
