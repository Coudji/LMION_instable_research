# LMION V3 current state / conversation handoff

Last updated: 2026-09-04

This file is the canonical handoff for active V3 development in `Coudji/LMION_instable_research`.

## Repository roles

- `Coudji/LMION_instable_research` — active V3 development/research workspace. Experimental commits and branches are acceptable here.
- `Coudji/LMION_Legacy` — V1/V2 archaeology, behavioral oracle and historical research source.
- separate clean LMION repository — reserved for release-quality source/history once V3 is validated. Do not use it as the unstable development target.

## Local development layout

This repository is designed to be pulled directly into a folder under the user's `Zomboid/Workshop/` directory.

The repository root must therefore remain directly usable by Project Zomboid Workshop tooling:

```text
LMION_instable_research/
├─ workshop.txt
├─ Contents/
│  └─ mods/
│     └─ LMION_DEV/
│        └─ 42/
│           └─ mod.info
├─ Docs/
├─ README.md
└─ CURRENT_STATE.md
```

Development identity is intentionally distinct from the future release mod:

```text
Workshop title: Let Me In... Or Not [DEV]
Mod id:         LMION_DEV
Mod folder:     Contents/mods/LMION_DEV
```

Keep `[DEV]` / `LMION_DEV` during unstable development so the development copy is visually and technically distinct from the future release package. The release repository may later use the normal `LMION` identity.

## Current product direction

LMION V3 will be **one gameplay mod with all official gameplay systems loaded together**.

The previous goal of independently loadable gameplay submods (`Core`, `Pickup`, `Build`, later `Lock`) is abandoned.
Do not reintroduce feature toggles as a substitute for separate submods: load-time hooks, SpriteGrid/script mutations and lifecycle-sensitive behavior make true runtime disablement unreliable and would recreate the same complexity.

Debug may remain a separate development tool because it is not player-facing gameplay functionality.

### Mandatory Build consequences

Build is part of the base LMION V3 product and is never optional.

This creates two hard gameplay contracts:

1. **Every LMION-created/finalized/reinstalled door or opening is an `IsoDoor`.** `IsoThumpable(isDoor)` may still appear as a vanilla/external/source representation at compatibility boundaries, but it is never the final LMION-managed representation.
2. **Supported vanilla LargeGates are always constructed as independent A and B leaves.** The old compatibility behavior where vanilla builds a complete A+B gate when Build is absent no longer exists because there is no Build-absent V3 composition.

Legacy already implements the Build-active vanilla large-gate split path. Recover its validated engine behavior when V3 reaches that subsystem, but reorganize it by V3 responsibility rather than copying the old addon structure.

Canonical decision document:

```text
Docs/Decisions/CanonicalDoorsAndLargeGates.md
```

## V3 code-quality rules

- one function = one responsibility/intention;
- one file = one identifiable responsibility;
- hooks are small adapters and delegate business logic;
- one owner per vanilla hook/behavior boundary;
- prefer calling the previous/original vanilla implementation instead of copying vanilla behavior;
- LMION takes control only where vanilla cannot satisfy the intended behavior, then gives control back as soon as practical;
- no generic routers/managers/bridges that know every family merely to reduce line count;
- prefer a few simple specialized implementations over one huge branch-heavy abstraction;
- do not mix pure code moves/refactors with behavior changes;
- abstractions must solve an existing duplicated contract, not hypothetical future needs;
- directory organization must make it obvious to a human where a behavior lives.

## Public addon API direction

LMION remains addon-friendly for external modders.

External addons should target a small stable facade such as:

```lua
local LMION = require "LMION/API"
```

Internal implementation paths are private and may change.

V2 concepts worth preserving after audit:

- explicit `definitionId`, `defaultId`, `extensionId`;
- pure data definitions/defaults;
- private Registry/Resolver internals;
- registration API such as `registerDefinition`, `registerDefault`, `registerExtension`, `registerContent`;
- explicit semantic `doorType`.

Current `doorType` vocabulary:

```text
Simple
Paired
FenceGate
Sliding
LargeGate
Garage
```

Future hypothetical types such as `LargeSliding` / `PairedSliding` are not implemented and must not drive present abstractions.

## Behavioral source of truth

When V2/refactor behavior conflicts with already validated behavior, `Coudji/LMION_Legacy/Legacy/Contents` wins.

Important established contracts to preserve unless explicitly redesigned:

- every LMION-managed final world door/opening is `IsoDoor`;
- HP/max HP survive pickup and replacement;
- standard framed doors require the correct frame;
- inventory right-click Place uses LMION-owned placement UI/cursor behavior where already established;
- vanilla Moveables toolbar should retain vanilla ghost/facing/click-drag behavior unless a narrow LMION adaptation is required;
- Garage inventory placement supports variable width;
- Garage toolbar intentionally remains fixed L3 through vanilla multisprite behavior;
- LargeGate operates per A/B leaf, each leaf containing two physical members/parcels;
- supported vanilla LargeGate construction is split into A/B leaves because Build is always active;
- Garage and LargeGate placement can consume compatible required parcels from inventory and nearby floor where Legacy supports it;
- compatible multi-part parcels are interchangeable by part identity; no bundle/assembly identity is currently desired;
- definitions should contain explicit geometry rather than inferred sprite arithmetic for complex types.

## Research guardrail

Before changing a PZ integration point that has already been researched, read the corresponding note first.

High-value source material currently lives in `Coudji/LMION_Legacy/Legacy/Research`, especially:

```text
Engine/B42LuaLoadOrder.md
Engine/LoadLifecycle.md
Moveables/VanillaMoveablesBehavior.md
Architecture/CoreEntityLookup.md
Architecture/DoorObjectAbstraction.md
```

Selected active research should be migrated into this repository under `Docs/Research/` as V3 needs it. Keep the legacy repo intact as the archival source.

Important known lifecycle facts:

- `media/scripts` are parsed before Lua and require full restart after changes;
- normal initial Lua execution is shared, then client; server Lua comes later in SP;
- dedicated server discovers but does not execute client Lua;
- files in an active Lua tree auto-execute in case-insensitive alphabetical path order;
- shared/client code must not require server-only vanilla Lua before server phase;
- `OnLoadedTileDefinitions` is authoritative for tile/sprite-derived mutations such as SpriteGrid/property state that can be reset by tile loading;
- `OnGameBoot` is used for script/GameEntity topology mutations when appropriate;
- `LoadGridsquare` / `OnObjectAdded` are for live world-instance adoption, not script topology;
- active cursors/actions/UI can retain stale closures after Lua reload;
- after hook/load-order structure changes, use a cold restart before concluding behavior is broken.

## Known V2 regression to avoid carrying forward

The last V2 LargeGate refactor ended with a toolbar ghost that displayed correctly but clicking did not place the gate.
The exact cancellation boundary was not instrumented before V2 was abandoned.

Do not resume speculative patching on that V2 stack. Recover validated Legacy behavior and instrument narrow vanilla boundaries before changing behavior.

## Initial V3 migration strategy

1. Seed this repository with only active V3 guardrails/docs and a clean package skeleton.
2. Copy/migrate data/API foundations only after auditing them; do not bulk-copy V2 runtime.
3. Port one small validated behavior path at a time.
4. Keep family implementations and hook ownership explicit and easy to locate.
5. Write expensive new discoveries into `Docs/Research/` before considering a bug/work item complete.
6. Keep this file updated at meaningful checkpoints and before/through long operations likely to span a conversation limit.

## Immediate next step

Begin migrating the minimal data/API foundation from `LMION_Legacy` into `Contents/mods/LMION_DEV/42/` without bringing over V2's oversized runtime files or obsolete independent-mod packaging.
