# Prayer calendar export

Active branch: `manual/prayer-calendar-export`, independently based on
`b846045`. Do not overwrite or duplicate the pending off-device reading branch.

## User flow

Prayer times → Monthly prayer times → Share calendar file → review → Share.
Exports all five daily prayer starts for the displayed month, regardless of the
display filter. Sunrise is excluded. Calculations use the same city, method,
Asr rule, high-latitude rule and adjustments as the monthly screen.

The confirmation explains place/time disclosure, the fixed snapshot, possible
duplicate imports and calendar-default reminders. The app does not request
calendar access, import automatically, or include VALARM components.

## Format and privacy

- RFC 5545: https://www.rfc-editor.org/rfc/rfc5545.html
- UTC DTSTART preserves per-date timezone/DST conversion.
- Events mark starts only: no claimed prayer validity interval or iqamah time.
- PRIVATE/TRANSPARENT events with stable place-label/timezone/date/prayer UIDs.
- UTF-8 folding at 75 octets and escaped text fields.
- No coordinate fields, attendees, account data or calendar-read permissions.
- Small export files stay in OS-managed temporary storage for share readers.
- Calendar applications may apply their own reminders/import rules; no promise
  of duplicate-free re-import or automatic synchronization is made.

## Validation and next step

Unit tests cover month counts, DST, minute adjustments, stable IDs, UTF-8 folding,
escaping, invalid input and UI language parity. A widget test covers confirmation
and cancellation. `Prayer calendar checks` runs only these and the existing
calculator tests, with a 15-minute cap. No APK is built.

Validation pending: inspect the branch's latest check before integration. The
local workspace has no Flutter SDK; local `git diff --check` passed. Native share
and calendar-import behavior still need Android/iOS device verification.
