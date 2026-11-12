# Changelog

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
