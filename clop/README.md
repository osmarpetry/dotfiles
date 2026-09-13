# clop

`preferences.selected.plist` is a hand-picked subset of Clop's preferences
(image/video watch folders, clipboard optimization, conversion settings —
never the license/private fields). `restore_clop_prefs.py` rewrites the
stale home path baked into the plist and merges it into the live
`~/Library/Preferences/com.lowtechguys.Clop.plist`, run by
`install-configured.sh`.

To pick up a new preference after changing Clop's settings by hand, re-export
the relevant keys into `preferences.selected.plist` — this is a manual,
reviewed step, not an automatic full-prefs dump.
