# LMION V3 current state / conversation handoff

Last updated: 2026-09-04

This file is the canonical handoff for active V3 development in `Coudji/LMION_instable_research`.

## Repository roles

- `Coudji/LMION_instable_research` — active V3 development/research workspace. Experimental commits and branches are acceptable here.
- `Coudji/LMION_Legacy` — V1/V2 archaeology, behavioral oracle and historical research source.
- separate clean LMION repository — reserved for release-quality source/history once V3 is validated.

## Local development layout

The repository is pulled directly under the user's `Zomboid/Workshop/` directory and must stay directly usable by PZ Workshop tooling:

```text
repo root/
├─ workshop.txt
├─ Contents/
│  └─ mods/
│     └─ LMION_DEV/
│        └─ 42/
├─ Docs/
├─ README.md
└─ CURRENT_STATE.md
```

Development identity:

```text
Workshop title: Let Me In... Or Not [DEV]
Mod id:         LMION_DEV
Mod folder:     Contents/mods/LMION_DEV
```

Keep `[DEV]` / `LMION_DEV` during unstable development so the dev copy cannot be confused with the future release package.

## Current product direction

LMION V3 is **one gameplay mod with all official gameplay systems loaded together**.

The old independently loadable `Core`, `Pickup`, `Build`, later `Lock` product architecture is abandoned. Do not reintroduce official feature toggles as a substitute.

Debug may remain a separate development tool.

### Mandatory Build consequences

Build is part of base LMION V3 and is never optional.

Hard contracts:

1. Every LMION-created/finalized/reinstalled door or opening is an `IsoDoor`. `IsoThumpable(isDoor)` may be read as a vanilla/external/source representation but is never a final LMION-managed representation.
2. Supported vanilla LargeGates are always constructed as independent A and B leaves. The old "Build absent -> construct complete gate" path no longer exists.

See `Docs/Decisions/CanonicalDoorsAndLargeGates.md`.

## V3 code-quality rules

- one function = one responsibility/intention;
- one file = one identifiable responsibility;
- hooks are small adapters and delegate business logic;
- one owner per vanilla hook/behavior boundary;
- prefer calling previous/original vanilla behavior rather than copying it;
- LMION takes control only where vanilla cannot satisfy the intended behavior;
- no generic routers/managers/bridges accumulating every family;
- prefer simple specialized implementations over branch-heavy abstractions;
- do not mix structural refactors with behavior changes;
- abstractions solve existing duplicated contracts, not hypothetical future needs;
- directory organization optimizes for human navigation.

## Public addon API direction

External addons should target:

```lua
local LMION = require "LMION/API"
```

Internal modules are private and may change.

Public data vocabulary currently includes explicit `defaultId`, `definitionId`, `extensionId` and semantic `doorType`.

Current `doorType` vocabulary:

```text
Simple
Paired
FenceGate
Sliding
LargeGate
Garage
```

Future hypothetical types such as `LargeSliding` / `PairedSliding` must not drive current abstractions.

## First active V3 foundation checkpoint

Commit:

```text
5e7c117245f88f13b0e03d76f5cbb574982d230b
```

Documentation commit:

```text
919771ac619e3669a0aa5cb62496112c9cbcfaea
```

The following data-only foundation now exists under `Contents/mods/LMION_DEV/42/media/lua/shared/`:

```text
LMION/
├─ API.lua
├─ Bootstrap/
│  └─ Definitions.lua
├─ Definitions/
│  ├─ Registry.lua
│  ├─ Resolver.lua
│  ├─ Validation.lua
│  ├─ BuiltinContent.lua
│  ├─ Defaults/
│  │  └─ Doors/WoodFourPanels.lua
│  └─ Catalog/
│     └─ Doors/Single/Wooden/WhitePanelDoor.lua
├─ Domain/
│  └─ DoorTypes.lua
└─ Support/
   └─ TableUtils.lua

LMION_DEV.lua
```

Responsibilities are documented in `Docs/Architecture/FoundationFiles.md`.

Important design choices already applied:

- `Registry` only stores raw registered data;
- `Validation` only validates public data shape;
- `Resolver` only produces effective definitions/defaults;
- `DoorTypes` owns the finite semantic type vocabulary and type-derived frame requirement;
- definitions expose `doorType`; transitional V2 `frame` data was deliberately not migrated into the first V3 default;
- `API.lua` is a small public facade and currently reports API version `1`;
- built-in data is explicitly listed in `Definitions/BuiltinContent.lua`; there is no directory scanning;
- `Bootstrap/Definitions.lua` registers built-ins exactly once through the same public API third-party addons use;
- `LMION_DEV.lua` is deliberately tiny and currently only bootstraps definitions and prints registration stats.

The first migrated concrete opening is `Doors.Wood.WhitePanelDoor`, using the V2 reviewed explicit N/W geometry and `Doors.Wood.FourPanels` default values.

### What is intentionally NOT in V3 yet

There is currently no:

- Pickup runtime;
- Build hook;
- Moveables hook;
- IsoDoor canonicalization runtime;
- Entity/world-object index;
- Garage runtime;
- LargeGate mutation;
- gameplay UI/cursor code.

Do not add those by bulk-copying V2 files.

## Behavioral source of truth

When V2/refactor behavior conflicts with already validated behavior, `Coudji/LMION_Legacy/Legacy/Contents` wins.

Established contracts to preserve unless explicitly redesigned:

- every LMION-managed final world opening is `IsoDoor`;
- HP/max HP survive pickup/replacement;
- standard framed doors require the correct frame;
- inventory right-click Place uses LMION-owned placement UX where established;
- vanilla Moveables toolbar keeps vanilla ghost/facing/click-drag behavior unless a narrow LMION adaptation is required;
- Garage inventory placement supports variable width;
- Garage toolbar intentionally remains fixed L3;
- LargeGate operates per A/B leaf, each leaf containing two physical members/parcels;
- supported vanilla LargeGate construction is split into A/B leaves;
- Garage/LargeGate placement can use compatible required parcels from inventory and nearby floor where Legacy supports it;
- compatible multipart parcels are interchangeable by part identity, with no bundle identity;
- definitions use explicit geometry rather than inferred sprite arithmetic for complex types.

## Research guardrail

Before changing a PZ integration point already researched, read the relevant note first.

High-value Legacy sources:

```text
Legacy/Research/Engine/B42LuaLoadOrder.md
Legacy/Research/Engine/LoadLifecycle.md
Legacy/Research/Moveables/VanillaMoveablesBehavior.md
Legacy/Research/Architecture/CoreEntityLookup.md
Legacy/Research/Architecture/DoorObjectAbstraction.md
```

Important known lifecycle facts:

- `media/scripts` parse before Lua and require cold restart after changes;
- normal initial Lua execution is shared then client; server Lua comes later in SP;
- dedicated server discovers but does not execute client Lua;
- active Lua-tree files autoexecute in case-insensitive alphabetical path order;
- shared/client code must not require server-only vanilla Lua before server phase;
- `OnLoadedTileDefinitions` is authoritative for tile/sprite-derived mutations that tile loading may reset;
- `OnGameBoot` is the validated point for selected GameEntity/SpriteConfig topology mutation;
- `LoadGridsquare` / `OnObjectAdded` concern live instances, not script topology;
- active cursors/actions/UI can retain stale closures after Lua reload;
- after hook/load-order structure changes, cold restart before rejecting behavior.

Any expensive new discovery must be written into active `Docs/Research/` before the related work is considered done.

## Known V2 regression to avoid carrying forward

The last V2 LargeGate refactor produced a complete toolbar ghost but clicking did not place the gate. The exact cancellation boundary was never instrumented.

Do not resume speculative patching on that stack. Recover validated Legacy behavior and instrument narrow boundaries when V3 reaches LargeGate.

## Immediate next step

Before adding runtime behavior, continue the data foundation in small auditable steps:

1. verify the first foundation boots cleanly in PZ and logs exactly one migrated default + one definition;
2. then migrate the remaining reviewed DefinitionDefaults/Catalog data, removing only transitional fields whose V3 replacement is already explicit;
3. add the entity/world-object lookup layer only after the data catalog is established and after re-reading the relevant research;
4. start runtime behavior with one simple 1x1 door path before Paired/Garage/LargeGate.

When a conversation resumes, read this file first, then `Docs/Architecture/FoundationFiles.md`, then only the research relevant to the subsystem being changed.
