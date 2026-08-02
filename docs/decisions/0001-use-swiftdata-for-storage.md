# ADR 0001: Use SwiftData for local storage

**Date:** 2026-08-02
**Status:** Accepted

## Context
FORGE needs local persistent storage for programs, workout sessions, 
exercise library, body weight entries, and (later) nutrition data. 
The app is SwiftUI-based, targets iOS 17+, and needs to share data 
with a Watch extension.

## Decision
Use SwiftData as the persistence layer.

## Alternatives considered
- **Core Data:** Mature and proven, but verbose and older API style. 
  Overkill for a solo project when SwiftData covers the same needs.
- **Plain files (JSON on disk):** Too fragile for relational data 
  (programs → days → exercises → sets). Query performance and 
  migration would become painful.

## Consequences
- Pairs cleanly with SwiftUI's `@Query` and `@Model`.
- Some sharp edges with complex relationships — accept and work around.
- Migration path exists to Core Data if SwiftData proves insufficient.

## Related
- ADR 0002 (Watch app architecture)
