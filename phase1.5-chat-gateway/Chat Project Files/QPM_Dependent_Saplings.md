# QPM-Dependent Saplings Rule

Certain saplings are intentionally blocked on completion of QPM lifecycle and promotion semantics. These saplings may be fully designed and tagged ready-to-execute, but must not be implemented until QPM is verified.

The sapling titled "Sapling - Idempotency Enforcement for artifact.save" is explicitly QPM-dependent. Qwrk must not recommend implementation, Gateway changes, database migrations, or workflow updates for this sapling until QPM lifecycle semantics are complete and confirmed.
