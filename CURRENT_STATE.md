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

## Development diagnostics policy

During unstable V3 development, prefer useful targeted logs over silent behavior.

- Add logs at important runtime boundaries when they help identify which branch/path actually executed.
- Include stable context such as definition ID, entity ID, door type, facing/member/leaf/role, selected vanilla boundary and success/failure reason when relevant.
- Avoid per-frame/per-tick spam unless temporarily diagnosing that exact loop.
- Diagnostic logs may be removed or reduced before release once the behavior is validated.
- When a bug crosses a vanilla hook boundary, log the narrow control point before adding speculative patches.

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

## Data/API foundation

Foundation commit:

```text
5e7c117245f88f13b0e03d76f5cbb574982d230b
```

The data/API foundation remains responsibility-oriented:

- Registry stores raw registered data and owns a registration revision counter;
- Validation validates public data shape only;
- Resolver resolves defaults/definitions/extensions only;
- EntityIndex derives `GameEntity full name -> definitionId` lazily from effective definitions;
- `PZ/WorldObjectIdentity` only reads `object:getEntityScript():getFullName()`;
- `Services/DefinitionLookup` combines identity and definition resolution;
- DoorTypes owns semantic type vocabulary and type-derived frame requirement;
- BuiltinContent explicitly lists registrations; no directory scanning.

See `Docs/Architecture/FoundationFiles.md`, `Docs/Architecture/CatalogData.md` and `Docs/Architecture/EntityLookup.md`.

## Complete built-in catalog migration

Main migration commit:

```text
94d935485ca5baaa4731615bef39b7846f13ba6f
```

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

Schema cleanup preserved the intended V3 rules: no redundant public `frame`, Paired uses explicit left/right geometry, Garage uses explicit START/MIDDLE/END geometry, LargeGate uses stable A/B identity.

The omitted `RoughWoodenDoor.lua` migration defect was fixed by:

```text
e55fcc0817892eedb7c8aa3c080bdf366f248b42
```

Registration diagnostics were improved by:

```text
3e39223af3d53e13a3337ecfc6ef48cbca109ba5
```

**VALIDÉ EN JEU** on 2026-09-04:

```text
[LMION:DEV] definitions ready: 23 defaults, 72 definitions, 0 extensions
```

The catalog/data migration is complete. Do not keep revisiting it unless a concrete defect, missing definition or API requirement is discovered.

## GameEntity lookup foundation

Research commit:

```text
5b45221c1893ff876f79d2a9bbc9f94ce046da94
```

Implementation commit:

```text
4ef94ad72b5f72fb1aaff1b8ea9e34962af571ef
```

Public API includes:

```lua
LMION.getDefinitionIdByEntity(entityId)
LMION.getEffectiveDefinitionByEntity(entityId)
LMION.getEntityIdForObject(object)
LMION.getDefinitionIdForObject(object)
LMION.getEffectiveDefinitionForObject(object)
```

Identity chain:

```text
world object
-> GameEntityScript full name
-> EntityIndex
-> definitionId
-> effective definition
```

**VALIDÉ EN JEU** as part of the first integrated Simple checkpoint on 2026-09-04:

```text
[LMION:DEV] entity index ready: 77 mappings; Base.WhitePanelDoor -> Doors.Wood.WhitePanelDoor
```

No sprite-based primary identity lookup or world scanning is used.

## First Simple 1x1 runtime foundation

The first functional pilot is intentionally limited to:

```text
Doors.Wood.WhitePanelDoor
Base.WhitePanelDoor
Base.LMION_WhitePanelDoor
```

Current runtime responsibilities are split under `PZ/`, `Runtime/`, `Services/Build/`, `Services/Moveables/`, `Hooks/Moveables/` and server `Hooks/Build/`.

Important files include:

```text
PZ/DoorObject.lua
PZ/DoorSprite.lua
PZ/StandardDoorFrame.lua
PZ/PlacedDoor.lua
PZ/BuiltDoor.lua
Runtime/DoorDurability.lua
Runtime/DoorState.lua
Runtime/DoorPlacement.lua
Runtime/CanonicalDoor.lua
Runtime/Moveables/DoorTransportState.lua
Runtime/Moveables/SimpleDoorSprites.lua
Services/Moveables/SimpleDoorProfiles.lua
Services/Moveables/SimpleDoorPlacementFinalizer.lua
Services/Build/ConstructionDurability.lua
Services/Build/SimpleDoorFinalizer.lua
Hooks/Moveables/SimpleDoor.lua
server/LMION/Hooks/Build/SimpleDoor.lua
```

Architecture and control-point notes:

```text
Docs/Architecture/DoorRuntimeFoundation.md
Docs/Research/Moveables/SimpleMoveablesHook.md
Docs/Research/Build/SimpleDoorBuildPilot.md
```

### Build pilot engine scripts

The pilot currently has:

```text
media/scripts/WhitePanelDoor_Item.txt
media/scripts/WhitePanelDoor_Build.txt
media/scripts/WhitePanelDoor_Entity.txt
```

The Build recipe was visible before the Entity SpriteConfig existed, but clicking Build created no cursor because vanilla had no selected build object for `Base.WhitePanelDoor`.

The missing SpriteConfig was restored in:

```text
75d637ed1d8c4332d8126db219f176ecb94eed58
Restore White Panel Door SpriteConfig for Build pilot
```

The restored faces are:

```text
W      fixtures_doors_01_0
N      fixtures_doors_01_1
W_OPEN fixtures_doors_01_2
N_OPEN fixtures_doors_01_3
```

This is engine support for vanilla Build; the LMION catalog remains the semantic/geometry source of truth.

### VALIDÉ EN JEU — complete Simple loop

2026-09-04.

User successfully exercised:

```text
Build White Panel Door
-> canonicalize built object
-> Pickup
-> inventory transport item
-> replace through Moveables
```

User explicitly confirmed:

- construction works;
- pickup works;
- replacement works;
- the standard frame requirement is respected;
- HP/max-HP persist through pickup/replacement.

Successful runtime logs include:

```text
[LMION:DEV] Simple Moveables hooks installed
[LMION:DEV] Simple Build hook installed: Doors.Wood.WhitePanelDoor
[LMION:DEV] Simple Moveables sprites configured: 4
[LMION:DEV] Simple Build finalizing: definition=Doors.Wood.WhitePanelDoor entity=Base.WhitePanelDoor representation=IsoThumpable
[LMION:DEV] canonical door ready: IsoDoor facing=W
[LMION:DEV] Simple Build finalized: definition=Doors.Wood.WhitePanelDoor representation=IsoDoor health=725 max=725
[LMION:DEV] Simple pickup state captured: definition=Doors.Wood.WhitePanelDoor health=725 max=725
[LMION:DEV] Simple transport item serialized: definition=Doors.Wood.WhitePanelDoor item=Base.LMION_WhitePanelDoor
[LMION:DEV] Simple placement started: definition=Doors.Wood.WhitePanelDoor facing=W sprite=fixtures_doors_01_0
[LMION:DEV] Simple placement finalized: definition=Doors.Wood.WhitePanelDoor sprite=fixtures_doors_01_0 health=725 max=725
```

This validates the first integrated path:

```text
GameEntity identity
-> LMION definition/profile
-> vanilla Build / Moveables
-> LMION canonical IsoDoor finalization
-> transported durability restore
```

The successful Build log proves the engine may initially create an `IsoThumpable`, and LMION correctly converges it to canonical `IsoDoor` before final ownership.

### Historical first Simple runtime failure

**ÉCHEC TESTÉ / NE PAS REFAIRE**: `SimpleDoorProfiles.getSingleSkillLevel()` initially used global `next()` and Kahlua reported `Object tried to call nil in getSingleSkillLevel` during `OnLoadedTileDefinitions`.

The fix uses `pairs()` and explicit entry counting. This failure occurred before Pickup/placement and did not invalidate the catalog or entity index.

## What is not yet validated/implemented broadly

The validated checkpoint covers one Simple definition only. Do not generalize its validation status to:

- every Simple door definition;
- Paired;
- FenceGate;
- Sliding;
- Garage;
- LargeGate.

The runtime abstractions are now proven by one complete Simple path, but catalog-wide activation and family-specific integration remain future work.

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

Important lifecycle facts:

- `media/scripts` parse before Lua and require cold restart after changes;
- normal initial Lua execution is shared then client; server Lua comes later in SP;
- shared/client code must not require server-only vanilla Lua before server phase;
- `OnLoadedTileDefinitions` is authoritative for tile/sprite mutations tile loading may reset;
- `OnGameBoot` is the validated point for selected GameEntity/SpriteConfig topology mutations;
- active cursors/actions/UI can retain stale closures after Lua reload;
- after hook/load-order structure changes, cold restart before rejecting behavior.

Any expensive new runtime discovery must be written into active `Docs/Research/` before the related work is considered done.

## Testing strategy

Do not request a PZ restart for every pure-data or pure-Lua slice.

The first integrated Simple milestone is now validated. Group subsequent changes and request another **TEST EN JEU REQUIS** only at the next meaningful runtime milestone. New or changed `media/scripts` still require a cold restart, so accumulate those changes before asking for one.

## Known LargeGate V2 regression to avoid

The last V2 LargeGate refactor produced a complete toolbar ghost but clicking did not place the gate. The exact cancellation boundary was never instrumented.

Do not resume speculative patching on that stack. Recover validated Legacy behavior and instrument narrow vanilla boundaries when V3 reaches LargeGate.

## Immediate next step

The data catalog, GameEntity lookup and one complete Simple 1x1 runtime path are established and validated.

Before expanding Simple support, inspect the current transport-item and Build-script requirements versus the full Simple catalog and Legacy scripts. Separate these questions instead of assuming one mechanism solves both:

```text
existing world Simple door -> pickup/replacement support
Simple definition -> vanilla Build construction support
```

Determine which engine-side item/GameEntity/CraftRecipe scripts are genuinely required for each path, then extend the validated Simple architecture without introducing duplicated hand-written script data unnecessarily.

Do not request another game launch until that expansion forms a meaningful integrated checkpoint.
