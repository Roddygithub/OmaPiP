# Changelog

## [0.2.2] - 2026-11-22

- Escalate the update checker to SIGKILL when its SIGTERM deadline is ignored instead of sending another SIGTERM.
- Release the placement slot only once the helper has exited, kill a wedged placement with SIGKILL after a second, and settle a placement whose start failed.
- Escalate a cancelled viewer configuration to SIGKILL and stop its watchdog.
- Read the Omarchy language file through a bounded 256-byte helper, polled twice a second, instead of a `FileView` that reads the whole file.

## [0.2.1] - 2026-11-12

- Cap the `hyprctl clients -j` answer while it is read and reject an over-long one instead of parsing it.
- Limit the picker to 64 source entries.
- Run placements one at a time, keep only the latest request and stop a wedged `hyprctl` after 3 seconds.
- Escalate the update checker to a hard stop when its deadline expires, and bound the update cache read.

## [0.2.0] - 2026-11-07

- Add local translation catalogs for all 50 Omarchy display languages and variants.
- Follow live language changes, support right-to-left interfaces and keep compositor selectors unchanged.
- Add daily, credential-free stable-release checks, deduplicated desktop notices and a bar indicator with update instructions.
- Add a `checkUpdates` setting to disable background release checks.
- Fit translated viewer controls inside narrow windows and wrap picker headings.
- Add catalog, language-switching and update-check regression tests.

Translations are machine-generated with common French terminology corrected manually; native-speaker review is welcome.
