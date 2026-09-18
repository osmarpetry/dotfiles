# Raycast

Full export/import uses an encrypted `.rayconfig` and restores settings, aliases, and hotkeys wholesale. Deliberately not used here — too much surface, includes token fields. Instead, only hotkeys are tracked, and recreated by hand.

Source: https://manual.raycast.com/import-export

## What's not copied

- `~/.config/raycast`
- `~/Library/Application Support/com.raycast.macos`
- `~/.config/raycast/config.json` (contains token fields)
- Full `.rayconfig` import

## Hotkeys to recreate manually

| App / Command | Hotkey |
|---|---|
| Activity Monitor | Option+Shift+Esc |
| Finder | Option+F |
| Ghostty | Option+Shift+T |
| Google Chrome | Option+1 |
| Microsoft To Do | Option+T |
| Notes | Option+Q |
| Notion | Option+N |
| OBS | Option+G |
| Steam | Option+S |
| T3 Code Alpha | Option+3 |
| Zed | Option+Z |
| Kill Process | Option+K |
| Obsidian Daily Note | Option+O |
| Search Emoji and Symbols | Control+Command+Space |
| Clipboard History | enabled, no hotkey |
| Raycast AI | enabled, no hotkey |

Full list also lives in `manifests/raycast_shortcuts.yml`. Disable or leave unconfigured everything else. Verify in Raycast Settings with "Show only customized" enabled.
