**Date:** 2026-08-02
**Status:** Accepted

## Context
Decided to design the SwiftData model as if you might enable CloudKit later, even without turning it on in v1. Concretely that means: every non-relationship property gets a default value or is optional, and relationships have explicit inverses. This is basically good practice anyway and costs nothing to do now. If you never turn on CloudKit, no loss. If you do, the migration is much smaller.

## Consequences
If ever decided, cloud sharing could be enabled
