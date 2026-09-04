# LMION V3 current state / conversation handoff

Last updated: 2026-09-04

This file is the canonical handoff for active V3 development in `Coudji/LMION_instable_research`.

## Repository roles

- `Coudji/LMION_instable_research` — active V3 development/research workspace. Experimental commits and branches are acceptable here.
- `Coudji/LMION_Legacy` — V1/V2 archaeology, behavioral oracle and historical research source.
- separate clean LMION repository — reserved for release-quality source/history once V3 is validated.

Do not modify the clean release repository or `PZMOD_LMION` during active V3 work unless explicitly requested.

## Local development layout

The repository is pulled directly under the user's `Zomboid/Workshop/` directory and must remain directly usable by PZ Workshop tooling:

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

Keep `[DEV]` / `LMION_DEV` during unstable development.

## Product contract

LMION V3 is **one gameplay mod with all official gameplay systems loaded together**. Pickup, Build and future official systems are internal responsibilities, not independently enabled mods. Debug may remain separate development tooling.

Build is mandatory. Therefore:

1. every LMION-created/finalized/reinstalled opening is an `IsoDoor`;
2. `IsoThumpable(isDoor)` is accepted only as a vanilla/external/source representation at narrow compatibility boundaries;
3. supported vanilla LargeGates are always constructed as independent logical leaves A and B;
4. the old V2 `Build absent -> construct complete A+B gate` path does not exist in V3.

Canonical decision: `Docs/Decisions/CanonicalDoorsAndLargeGates.md`.

## Code-quality rules

- one function = one responsibility/intention;
- one file = one identifiable responsibility;
- hooks are thin adapters and delegate business logic;
- one owner per vanilla behavior boundary;
- prefer previous/original vanilla behavior wherever it remains correct;
- LMION takes control only where vanilla cannot satisfy the intended behavior;
- no universal routers/managers/bridges accumulating every family;
- prefer simple specialized implementations over branch-heavy abstractions;
- do not mix structural refactors with behavior changes;
- abstractions solve existing duplicated contracts, not hypothetical future needs;
- organize source by technical responsibility first, family specialization second.

## Public addon API

External addons target:

```lua
local LMION = require "LMION/API"
```

Internal modules are private and may change.

Current public semantic `doorType` vocabulary:

```text
Simple
Paired
FenceGate
Sliding
LargeGate
Garage
```

Future hypothetical types such as `LargeSliding` / `PairedSliding` must not drive current abstractions.

`doorType` is the semantic fact. Frame requirements are internal consequences owned by `Domain/DoorTypes.lua`:

```text
Simple    -> standard
Paired    -> paired
FenceGate -> none
Sliding   -> none
LargeGate -> none
Garage    -> none
```

Do not restore the old public `frame` field merely to duplicate this information.

## Active V3 data/API foundation

Foundation commit:

```text
5e7c117245f88f13b0e03d76f5cbb574982d230b
```

Important files under `Contents/mods/LMION_DEV/42/media/lua/shared/`:

```text
LMION/
├─ API.lua
├─ Bootstrap/Definitions.lua
├─ Definitions/
│  ├─ Registry.lua
│  ├─ Resolver.lua
│  ├─ Validation.lua
│  ├─ BuiltinContent.lua
│  ├─ Defaults/
│  └─ Catalog/
├─ Domain/DoorTypes.lua
└─ Support/TableUtils.lua

LMION_DEV.lua
```

Responsibilities:

- `Registry` stores raw registered data only;
- `Validation` validates public data shape only;
- `Resolver` resolves defaults/definitions/extensions only;
- `DoorTypes` owns semantic type vocabulary and type-derived frame requirement;
- `BuiltinContent.lua` explicitly lists built-in registrations; no directory scanning;
- `Bootstrap/Definitions.lua` registers built-ins once through the same public API used by third parties;
- `LMION_DEV.lua` stays a tiny bootstrap/diagnostic entry point.

See `Docs/Architecture/FoundationFiles.md`.

## In-game foundation validation

**VALIDÉ EN JEU** on 2026-09-04:

```text
LOG  : Lua          f:0> [LMION:DEV] definitions ready: 1 defaults, 1 definitions, 0 extensions
```

Then the first larger catalog slice was also **VALIDÉ EN JEU**:

```text
LOG  : Lua          f:0> [LMION:DEV] definitions ready: 5 defaults, 5 definitions, 0 extensions
```

These checkpoints validate the Workshop package path and the shared Lua `API -> Bootstrap -> Validation -> Registry` loading chain.

## Complete built-in catalog migration

Main migration commit:

```text
94d935485ca5baaa4731615bef39b7846f13ba6f
```

Architecture note:

```text
Docs/Architecture/CatalogData.md
```

The entire reviewed V2 `DefinitionDefaults` + `Catalog` dataset listed by Legacy `Core/BuiltinContent.lua` has now been migrated into the V3 responsibility-based layout.

Current built-in data count:

```text
23 defaults
72 concrete definitions
0 built-in extensions
```

Definitions by family:

```text
Doors/Paired          5
Doors/Single/Metal   16
Doors/Single/Wooden  27
FenceGates            9
GarageDoors           7
LargeGates            6
SlidingDoors          2
                     --
Total                 72
```

### Schema cleanup applied during migration

- old redundant `frame = "standard"`, `"paired"` or `"none"` fields were removed where `doorType` already expresses the semantic type;
- standalone definitions that cannot inherit `doorType` now state it explicitly;
- Paired definitions keep `doorType = "Paired"`, `entities.left/right` and explicit left/right geometry;
- Garage definitions keep explicit `START/MIDDLE/END` geometry but the redundant V2 `topology = { type = "garage" }` field was removed;
- LargeGate definitions keep explicit A/B geometry; A/B remains stable logical identity;
- exact entity IDs, explicit sprite geometry and gameplay-data overrides were preserved from the reviewed V2 dataset.

This full migration is **DATA-ONLY / NOT SEPARATELY VALIDATED IN GAME**. Do not ask for one PZ restart per catalog batch. The user explicitly wants meaningful runtime checkpoints only.

The catalog/data migration is now considered complete. Do not keep revisiting it unless a concrete defect, missing definition or API requirement is discovered.

## What is intentionally NOT in V3 yet

There is currently no:

- Pickup runtime;
- Build hook/runtime;
- Moveables hook;
- IsoDoor canonicalization runtime;
- entity/world-object reverse lookup layer;
- Garage runtime;
- LargeGate mutation/runtime;
- gameplay UI/cursor code.

Do not bulk-copy V2 runtime files to add these.

## Behavioral source of truth

When V2/refactor behavior conflicts with validated behavior, `Coudji/LMION_Legacy/Legacy/Contents` wins.

Established contracts include:

- every LMION-managed final world opening is `IsoDoor`;
- HP/max HP survive pickup/replacement;
- standard framed doors require correct frame;
- inventory right-click Place uses LMION-owned placement UX where established;
- vanilla Moveables toolbar keeps vanilla ghost/facing/click-drag behavior unless a narrow LMION adaptation is required;
- Garage inventory placement supports variable width;
- Garage toolbar intentionally remains fixed L3;
- LargeGate operates per A/B leaf, each leaf containing two physical members/parcels;
- supported vanilla LargeGate construction is split into A/B leaves;
- Garage/LargeGate placement can use compatible parcels from inventory and nearby floor where Legacy supports it;
- compatible multipart parcels are interchangeable by part identity, with no bundle identity;
- complex definitions use explicit geometry rather than inferred sprite arithmetic.

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

Important lifecycle facts:

- `media/scripts` parse before Lua and require cold restart after changes;
- normal initial Lua execution is shared then client; server Lua comes later in SP;
- dedicated server discovers but does not execute client Lua;
- active Lua-tree files autoexecute in case-insensitive alphabetical path order;
- shared/client code must not require server-only vanilla Lua before server phase;
- `OnLoadedTileDefinitions` is authoritative for tile/sprite mutations tile loading may reset;
- `OnGameBoot` is the validated point for selected GameEntity/SpriteConfig topology mutations;
- `LoadGridsquare` / `OnObjectAdded` concern live instances, not script topology;
- active cursors/actions/UI can retain stale closures after Lua reload;
- after hook/load-order structure changes, cold restart before rejecting behavior.

Any expensive new runtime discovery must be written into active `Docs/Research/` before the related work is considered done.

## Known LargeGate V2 regression to avoid

The last V2 LargeGate refactor produced a complete toolbar ghost but clicking did not place the gate. The exact cancellation boundary was never instrumented.

Do not resume speculative patching on that stack. Recover validated Legacy behavior and instrument narrow vanilla boundaries when V3 reaches LargeGate.

## Immediate next step

The catalog migration is finished.

Next:

1. re-read/migrate the relevant `CoreEntityLookup.md` research;
2. design the smallest responsibility-focused entity -> definition reverse lookup layer, with no vanilla hooks yet;
3. validate that lookup against the registered catalog without introducing gameplay behavior;
4. then port the first known-good Simple 1x1 runtime path from Legacy;
5. request an in-game test only at a meaningful runtime checkpoint, not for every data commit.

When resuming a future conversation, read this file first, then `Docs/Architecture/FoundationFiles.md` / `CatalogData.md`, then only the research relevant to the subsystem being changed.
