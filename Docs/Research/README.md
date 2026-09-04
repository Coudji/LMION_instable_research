# LMION V3 research

This directory contains technical findings that actively constrain V3 implementation.

The historical research archive remains in `Coudji/LMION_Legacy/Legacy/Research`.
Do not bulk-copy that archive here. Migrate only findings that still matter to V3, cleaning obsolete V1/V2 packaging conclusions while preserving the evidence and engine facts.

## Rule

Before changing a Project Zomboid integration point that has already been researched, read the relevant note first.

Any expensive new discovery should be written here before the related bug/work item is considered complete.

A useful research note records:

1. question or symptom;
2. evidence/source;
3. conclusion;
4. LMION decision;
5. rejected or failed approaches;
6. lifecycle/load-order constraint when relevant;
7. addon-facing contract when relevant;
8. what would require revalidation.

Failed approaches are worth preserving when they prevent repeating expensive dead ends.

## High-value legacy sources to migrate when first needed

- `Engine/B42LuaLoadOrder.md`
- `Engine/LoadLifecycle.md`
- `Moveables/VanillaMoveablesBehavior.md`
- `Architecture/CoreEntityLookup.md`
- `Architecture/DoorObjectAbstraction.md`

The legacy repository remains the archival source of truth for those original notes until a V3-specific version is deliberately migrated here.
