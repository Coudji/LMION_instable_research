# LMION V3 current state / conversation handoff

Last updated: 2026-09-11

This file is the canonical handoff for active V3 development in `Coudji/LMION_instable_research`.

## Repository roles

- `Coudji/LMION_instable_research` — active V3 development repository.
- `Coudji/LMION_Legacy` — **functional behavioral oracle**. Validated Legacy gameplay wins over refactor-era ideas.
- `LMION_Legacy/Workshop` — failed/abandoned refactor attempt. Useful for archaeology only; not a behavioral oracle.
- do not modify Legacy unless explicitly requested.

Current dev mod:

```text
Workshop title: Let Me In... Or Not [DEV]
Mod id:         LMION_DEV
Mod folder:     Contents/mods/LMION_DEV
```

## Non-negotiable refactor rules

V3 must reproduce known-good Legacy behavior with simpler, readable, maintainable code.

- one gameplay mod; no old Core/Pickup/Build split into separate mods;
- simple functions and clear names;
- one function = one identifiable responsibility;
- one file = one identifiable responsibility;
- split files before they become difficult to read;
- hooks are thin adapters around real vanilla boundaries;
- one vanilla boundary should have one owner;
- no catch-all routers/managers/bridges;
- no speculative abstractions before duplicate behavior is proven;
- public definitions contain semantic/data facts, not derivable runtime implementation details;
- addon authors must be able to understand the API without relying on internals;
- keep research/handoff documents current;
- record failed approaches so future conversations do not repeat them;
- when engine behavior is uncertain, inspect B42 vanilla Lua and/or the supplied JAR instead of guessing.

## Canonical opening rules

- every final LMION-managed opening is an `IsoDoor`;
- `IsoThumpable(isDoor)` is accepted only as source/vanilla/external input at a narrow boundary;
- HP/max HP survive pickup/replacement;
- Simple requires a standard frame;
- Paired has independent `left` / `right` 1x1 leaves and matching paired frame sides;
- FenceGate and Sliding require no frame;
- LargeGate uses stable logical leaf identity `A` / `B`, never left/right;
- Garage uses explicit START/MIDDLE/END geometry.

Semantic `doorType` values:

```text
Simple
Paired
FenceGate
Sliding
LargeGate
Garage
```

Internal frame consequence:

```text
Simple    -> standard
Paired    -> paired
FenceGate -> none
Sliding   -> none
LargeGate -> none
Garage    -> none
```

Do not restore redundant public frame/topology fields when the consequence can be derived internally.

Canonical decision: `Docs/Decisions/CanonicalDoorsAndLargeGates.md`.

## Data/API foundation — VALIDATED

External addons use:

```lua
local LMION = require "LMION/API"
```

Current built-in catalog:

```text
23 defaults
72 definitions
0 built-in extensions
```

By family:

```text
Doors/Paired          5
Doors/Single/Metal   16
Doors/Single/Wooden  27
FenceGates            9
GarageDoors           7
LargeGates            6
SlidingDoors          2
```

Validated startup diagnostics include:

```text
[LMION:DEV] definitions ready: 23 defaults, 72 definitions, 0 extensions
[LMION:DEV] entity index ready: 77 mappings; Base.WhitePanelDoor -> Doors.Wood.WhitePanelDoor
```

GameEntity reverse lookup uses:

```text
world object
-> object:getEntityScript():getFullName()
-> EntityIndex
-> definitionId
-> effective definition
```

## Definitions / addon-facing rules

Definitions/defaults are pure data with explicit identities:

```text
definitionId
defaultId
extensionId
```

`doorType` is the semantic discriminator. Runtime frame/topology/placement consequences are derived internally where possible.

Paired definitions explicitly use `doorType = "Paired"`. They do not expose a public frame-side/topology field because geometry already defines left/right.

LargeGate definitions expose exact N/W A/B geometry but not implementation-specific parcel or topology fields.

Validation remains intentionally structural/minimal. Full strict schema validation is deferred until the public API shape is complete.

## Single-tile integrated checkpoint — VALIDATED IN GAME

Current runtime-proven pilots:

```text
Doors.Wood.WhitePanelDoor
Doors.Wood.BlueChurchDoubleDoor
FenceGates.Wood.SmallWhiteWoodenGate
SlidingDoors.BrownSlidingGlassDoor
```

Validated behavior across those pilots as applicable:

```text
Build
Pickup
replacement
N/W placement/rotation
standard/paired/no-frame rules
HP/max-HP persistence
MetalWelding Moveables tool bridge
canonical final IsoDoor
```

This validates the architecture and those pilots, not every catalog definition.

## Script convention

Use one PZ script file per opening/family rather than separate `_Item`, `_Build`, `_Entity` files.

Script files contain only parse-time facts PZ actually needs, such as transport items, XUI, CraftRecipe and SpriteConfig. LMION Lua definitions remain authoritative for semantic type, durability, geometry and gameplay data.

## LargeGate runtime — PARTIALLY VALIDATED IN GAME

LargeGate V3 has family-specific services for:

```text
profile/segment lookup
A/B topology
runtime closed SpriteGrids
leaf pickup
parcel lookup/consumption
placement planning
partner open/closed detection
placement finalization
Moveables ghost rendering
Build leaf GameEntities/finalization
```

Legacy remains the contract:

```text
pickup/replacement per A/B leaf
2 physical members/parcels per leaf
inventory + nearby-floor parcel lookup
N/W behavior
partner-state coherence
HP/max-HP persistence
```

### Failure 1 — generic parcel had no WorldSprite

Tested commit:

```text
5841a976ae8d2cf7f1928825fd266f76158c1b00
```

Observed:

```text
pickup produced parcels
inventory right-click placement failed
toolbar placement failed
```

Cause: all LargeGate segments used generic `Base.LMION_OpeningParcel` with LMION identity only in modData and no Moveable WorldSprite.

**FAILED APPROACH / DO NOT REINTRODUCE:** a universal LargeGate package that replaces engine-visible segment identity.

### Transport identity correction — commit b92705e

V3 restored the Legacy physical parcel model:

```text
LMION_<Gate>A_Part1
LMION_<Gate>A_Part2
LMION_<Gate>B_Part1
LMION_<Gate>B_Part2
```

The four declarations live in each gate's normal script file. Item names are internal consequences of the opening entity and are not public definition fields. Parcels use their canonical closed segment WorldSprite and `Icon = Flatpack`; LMION modData carries definition/leaf/part and durability.

### 2026-09-11 in-game result on b92705e

Game log reports Project Zomboid **42.20.4**.

Tested with `LargeGates.Metal.DoubleWireGate`, leaf B, facing N:

```text
pickup succeeded -> 2 parcels
part 2 in inventory
part 1 on nearby floor
toolbar placement succeeded
right-click inventory placement also succeeded
placed leaf was functional
both physical members finalized as IsoDoor
```

This validates that the segment-item + WorldSprite correction repaired both placement frontends and that mixed inventory/floor **lookup** works.

Remaining defect from that test:

```text
floor parcel was not consumed after successful placement
inventory parcel was consumed
same defect through toolbar and right-click placement
```

The placement log reached `LargeGate placement completed`, so the old consumption helper incorrectly reported success even though the floor `IsoWorldInventoryObject` remained visible.

### Historical comparison: Legacy vs Workshop/V3 pickup lifecycle

This is now a documented regression boundary.

Known-good Legacy LargeGate pickup does **not** manually construct/deliver/remove each parcel. For every physical member it creates `ISMoveableSpriteProps` and delegates to vanilla:

```text
moveProps.isMultiSprite = true
-> moveProps:pickUpMoveableInternal(...)
```

Vanilla therefore owns item creation, `ReadFromWorldSprite`, component transfer, world-item delivery and source-object removal.

The failed Workshop refactor replaced that path with `MultiSquarePickupInternal`, which manually created the item, manually added it to the floor and manually removed the source. The first V3 LargeGate implementation independently recreated the same class of manual lifecycle using `LargeGateParcelFactory` + `MoveableDoorSegmentPickup`.

**FAILED REFACTOR PATTERN / DO NOT REINTRODUCE BY DEFAULT:** manually recreating vanilla multipart Moveable pickup when Legacy proves the vanilla `pickUpMoveableInternal()` path works.

### Current correction awaiting re-test

LargeGate pickup has been returned to the validated Legacy boundary:

```text
LargeGate high-level hook resolves the two members
-> each member calls vanilla pickUpMoveableInternal()
-> the existing single owner of instanceItem/pickUpMoveableInternal adds LMION identity + durability
```

No second hook owner was added.

The custom LargeGate placement remains unchanged because it already successfully rebuilds/finalizes the leaf. Floor consumption keeps the same removal sequence used by vanilla and Legacy, but now verifies that the world object actually disappeared before reporting success.

This correction is **NOT YET VALIDATED IN GAME**.

Research:

```text
Docs/Research/Moveables/FlatpackTransport.md
Docs/Research/Moveables/VanillaMoveablesBehavior.md
Docs/Research/Moveables/LargeGateGhostRendering.md
```

## LargeGate Build status

LargeGate Build code exists, including vanilla full-gate narrowing for supported vanilla entities, A/B GameEntity profiles and post-build canonicalization.

It remains **NOT VALIDATED IN GAME** as an integrated LargeGate Build checkpoint. Keep Build validation separate from Moveables replacement tests.

## Garage status

Garage definitions/defaults are migrated, but Garage V3 runtime is not yet ported.

Legacy Garage remains the contract, including:

```text
inventory placement -> variable width
toolbar placement -> intentionally fixed L3
N/W
START/MIDDLE*/END parcels
inventory + nearby-floor parcel lookup
transactional placement/rollback
HP persistence
```

Do not redesign Garage behavior from the V3 LargeGate implementation.

## Historical failures / do not repeat

**TESTED FAILURE / DO NOT REPEAT:**

- Kahlua global `next()` was nil in a profile path. Use `pairs()` + explicit counting.
- Build CraftRecipe without a GameEntity SpriteConfig can appear in the menu but clicking Build produces no cursor.
- V2 LargeGate toolbar could show a complete ghost while click placement failed; do not resume speculative V2 patches.
- V3 generic `Base.LMION_OpeningParcel` without a WorldSprite broke both LargeGate placement frontends on `5841a976...`.
- Workshop/manual multipart pickup lifecycle is not the behavioral reference; Legacy delegates each LargeGate member to vanilla `pickUpMoveableInternal()`.
- A successful placement log is not proof of parcel consumption; floor-world-object removal must be verified when debugging this path.

General rule: inspect vanilla Lua/JAR before changing an engine boundary and record the result here or under `Docs/Research`.

## Validation summary

**VALIDATED IN GAME:**

- built-in catalog startup 23/72/0;
- existing GameEntity reverse lookup checkpoint;
- White Panel Simple pilot;
- Blue Church Paired pilot;
- Small White Wooden FenceGate pilot;
- Brown Sliding Glass Door pilot;
- N/W behavior for those pilots;
- their frame/no-frame contracts;
- HP/max-HP persistence for those pilots;
- MetalWelding Moveables tool bridge through Sliding;
- LargeGate segment item + WorldSprite is sufficient for both toolbar and right-click placement to create a functional leaf;
- LargeGate mixed inventory/floor parcel lookup works.

**KNOWN LARGEGATE DEFECT UNDER CORRECTION:**

- on `b92705e`, a nearby-floor parcel was left behind after otherwise successful placement.

**IMPLEMENTED BUT RE-TEST REQUIRED:**

- LargeGate pickup restored to vanilla `pickUpMoveableInternal()` per physical member;
- verified floor-consumption result reporting;
- LargeGate Build runtime.

**NOT YET IMPLEMENTED/VALIDATED BROADLY:**

- remaining Simple definitions;
- remaining Paired definitions;
- remaining FenceGate definitions;
- remaining Sliding definitions;
- Garage V3 runtime.

## Immediate next test

Use a freshly picked-up LargeGate leaf after the latest pickup-lifecycle correction:

```text
1. Pickup one A or B leaf -> confirm 2 floor parcels.
2. Put one parcel in inventory; leave the other on the floor.
3. Place from toolbar.
4. Confirm BOTH parcels disappear.
5. Repeat from inventory right-click Place.
```

If the floor parcel still remains, use the new consumption failure log/result as the next boundary. Do not alter placement geometry/finalization while it remains functional.
