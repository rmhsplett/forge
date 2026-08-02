# ADR 0002: CloudKit-compatible data model, no sync in v1

**Date:** 2026-08-02
**Status:** Accepted

## Context
FORGE v1 is a single-device app. Multi-device sync (iCloud) is not 
needed now but may be wanted later — either for personal use across 
devices or as a commercial feature.

## Decision
Design the SwiftData model to be CloudKit-compatible from day one, 
but do not enable CloudKit sync in v1.

Concretely: every non-relationship property has a default value or 
is optional, and relationships have explicit inverses declared.

## Alternatives considered
- **Enable CloudKit in v1:** Adds complexity (conflict resolution, 
  offline queue) for no immediate benefit.
- **Ignore CloudKit constraints entirely:** Would force a painful 
  model migration if sync is ever added.

## Consequences
- Small design discipline cost now, large flexibility gain later.
- Enabling CloudKit later is a capability toggle + entitlement, 
  not a model rewrite.

## Related
- ADR 0007 (data model split)
