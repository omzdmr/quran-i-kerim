# Audio recovery queue handoff

Staging commits: 6c963cf, bb43886.

Profile > Downloads now exposes a FIFO batch recovery queue for incomplete audio packs.
Duplicate work is suppressed. Active work can be paused and pending work cleared.
Failed items stay visible but are not retried in a hot loop.

Batch start follows existing offline, Wi-Fi-only and mobile-confirmation settings.
Before every queued pack, network state is checked again. If connectivity or policy
changes, the queue pauses before dequeuing the next pack instead of silently moving
onto mobile data.

The queue itself is ephemeral. Existing offline pack intent records remain the restart
recovery source. Audio files, partials and cache remain re-downloadable device-local
data and are not added to portable backup. Existing pack-intent backup behavior is unchanged.

Tests now cover FIFO ordering, deduplication, remove/clear and policy-preflight pause.
Local Flutter tooling is unavailable in this worker and staging has no workflow run,
so formatter/analyzer/widget validation is still required before integration.

Next: real platform free-space probe, conservative reserved-headroom preflight,
actionable insufficient-space UI, then queue widget coverage.


Follow-up commits `ced1ffe` and `4be89c8` add an estimated remaining-download
workload and deletion/queue coherence. Deleting a pack or an entire voice removes
matching pending queue work and cancels matching active work, preventing deleted media
from being recreated by an old queue entry. Per-item network preflight remains
fail-closed when connectivity policy changes.
