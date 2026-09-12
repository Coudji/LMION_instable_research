# LMION V3 current state / conversation handoff

Last updated: 2026-09-12

This file is the canonical handoff for active V3 development in `Coudji/LMION_instable_research`.

## Repository roles

- `Coudji/LMION_instable_research` — active V3 development repository.
- `Coudji/LMION_Legacy` — **functional behavioral oracle**. Validated Legacy gameplay wins over refactor-era ideas.
- `LMION_Legacy/Workshop` — failed/abandoned refactor attempt. Useful for archaeology only; not a behavioral oracle, except Garage resource/cost archaeology where it contains the refined model later confirmed by the user.
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

## LargeGate runtime — MOVEABLES REPLACEMENT VALIDATED IN GAME

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

### 2026-09-11 initial in-game result on b92705e

Game log reports Project Zomboid **42.20.4**.

Tested with `LargeGates.Metal.DoubleWireGate`, mixed inventory/floor parcels:

```text
pickup succeeded -> 2 parcels
placement succeeded from toolbar and inventory right-click
placed leaf was functional
both physical members finalized as IsoDoor
```

This validated that segment-item + WorldSprite restored both placement frontends and that mixed inventory/floor lookup worked.

A remaining defect was then isolated:

```text
Part1 inventory + Part2 floor -> both consumed
Part2 inventory + Part1 floor -> placement succeeded but Part1 remained on floor
```

The floor Part1 was definitely the parcel used by placement because its HP/maxHP reached the placed Part1. The defect was therefore after selection, not a missing/wrong lookup.

### Historical comparison: Legacy vs Workshop/V3 pickup lifecycle

Known-good Legacy LargeGate pickup delegates each physical member to vanilla `pickUpMoveableInternal()` with `isMultiSprite = true`. Vanilla owns item creation, `ReadFromWorldSprite`, world-item delivery and source-object removal.

The failed Workshop refactor used a manual multipart lifecycle. The first V3 implementation independently recreated the same class of manual lifecycle.

V3 has returned pickup to the validated Legacy/vanilla boundary:

```text
LargeGate high-level hook resolves the two members
-> each member calls vanilla pickUpMoveableInternal()
-> the existing single owner of instanceItem/pickUpMoveableInternal adds LMION identity + durability
```

**FAILED REFACTOR PATTERN / DO NOT REINTRODUCE BY DEFAULT:** manually recreating vanilla multipart Moveable pickup when Legacy proves the vanilla path works.

### Final floor-parcel correction — VALIDATED

The successful correction does **not** replace PZ's world-item removal calls. It preserves the identity of the exact floor object selected before placement:

```text
floor lookup
-> return item + source + exact IsoWorldInventoryObject
-> retain exact world object in placement plan
-> place/finalize both members
-> consume that retained world object
```

The former `preferred`/cursor-item privilege was also removed. Part1 and Part2 are now resolved independently from the available stock, matching Legacy behavior.

Relevant commits:

```text
1d83215c209053830384e7d7bd330b110bc494ec  Align LargeGate placement lookup with Legacy
a37ead498fc1f2ee26d5164e44ca30b5d8113cee  Capture exact LargeGate floor parcel object
4b097bbf9a81a76bc4b9fbf29ff853c06c553179  Retain selected LargeGate floor world object
5cb06b60129ab61d83f19cdf04535d942e5b20cb  Consume exact selected LargeGate floor parcel
613b4ef14e716f71c7ccedc0a4ae4058cc6ca851  Use exact floor parcel during LargeGate placement
```

User re-tested the previously failing case after `613b4ef...` and confirmed: **it works**.

Validated LargeGate replacement semantics now include:

```text
Part1 and Part2 are independent stock pieces
inventory + nearby floor may be mixed in either arrangement
pickup origin does not pair the pieces
HP/maxHP follows the selected parcel
both selected parcels are consumed
functional canonical IsoDoor leaf is reconstructed
```

Research:

```text
Docs/Research/Moveables/FlatpackTransport.md
Docs/Research/Moveables/VanillaMoveablesBehavior.md
Docs/Research/Moveables/LargeGateGhostRendering.md
```

## LargeGate Build status

LargeGate Build code exists, including vanilla full-gate narrowing for supported vanilla entities, A/B GameEntity profiles and post-build canonicalization.

It remains **NOT VALIDATED IN GAME** as an integrated LargeGate Build checkpoint. Keep Build validation separate from Moveables replacement tests.

## Garage runtime — CORE WORKFLOW VALIDATED IN GAME

Garage V3 runtime is now ported. Legacy remains the behavioral oracle; Workshop resource formulas are the resource/cost reference confirmed by the user.

Core validated on Project Zomboid 42.20.4 with `GarageDoors.GreenGarageDoor`:

```text
Build L3 succeeds
Build L6 succeeds
pickup L3 succeeds when MetalWelding 3 requirement is met/bypassed
pickup L6 succeeds
inventory replacement L3 succeeds
variable replacement from L6 stock responds correctly to +/- width controls
requested replacement width is placed correctly
```

The initial pickup failure observed during testing was expected skill gating: the character had MetalWelding 2 while Garage pickup requires 3. Enabling Moveables cheat confirmed the chain pickup itself worked.

The fixed technical L3 SpriteGrid briefly leaked into L6 pickup rendering. Commit:

```text
3ab07fc740e809fc40c6800bc61ae7c4c72d175c  Render full Garage chain during pickup
```

changes pickup rendering to use the actual native START/MIDDLE*/END chain footprint.

A separate replacement error occurred after otherwise successful placement:

```text
attempted index: getSoundFromTool of non-table: null
ISMoveablesAction.setActionSound
```

Cause: the dedicated V3 Garage placement action was missing the normal Moveables context fields supplied by the known-good Legacy implementation. Commit:

```text
3fcb7e90043e235c8974206bb708855a289ed730  Restore Garage placement action Moveables context
```

restored `moveProps`, `origMoveProps` and `origSpriteName`. User retest after this correction: **works**.

Garage contract implemented:

```text
pickup may collect the complete physical garage
inventory placement -> variable width chosen from available stock
toolbar placement -> intentionally fixed L3
N/W
START / MIDDLE* / END stock model
inventory first + nearby-floor lookup
for requested length L consume exactly 1 START + (L-2) MIDDLE + 1 END
extra parcels remain untouched
HP/maxHP persists per selected parcel/member
placement prevalidates complete plan and rolls back created members on creation/finalization failure
```

Garage placement controls/policy:

```text
width decrease/increase keys are client Mod Options keybinds
rotation uses the normal PZ Rotate building bind and remains N/W only
width limit is controlled by Sandbox options
LMION.GarageMaxLength integer 6..12, default 6
LMION.UnlimitedGarageWidth disables LMION's artificial cap
minimum placeable garage length remains L2
```

`LMION/Domain/GarageLengthPolicy.lua` is the single runtime policy boundary for the garage cap.

Build costs for selected length L:

```text
MetalBar/IronBar combined = L
Hinge                     = 2L
solid SmallSheetMetal      = 3L
glazed SmallSheetMetal     = 2L
glazed GlassPanel          = L
BlowTorch uses             = min(ceil(L/3), 10)
WeldingRods uses           = min(2*ceil(L/3), 20)
```

Base CraftRecipe remains L2 and LMION consumes only the delta not already consumed by vanilla. Native selected bar quota is synchronized to L.

Research/status:

```text
Docs/Research/Moveables/GarageV3PortStatus.md
```

Still to validate explicitly before calling Garage broadly complete:

```text
all 7 Garage families
both N/W orientations as a full matrix
open Garage pickup/replacement
toolbar fixed-L3 checkpoint
mixed inventory/floor START/MIDDLE/END combinations
pickup L6 -> place L3 -> exactly 3 surplus parcels remain
damaged HP/maxHP survival
exact floor parcel consumption
solid/glazed exact resource consumption outside Build cheat
mixed MetalBar/IronBar and ground/container Build stock
higher Sandbox cap/unlimited
rollback/failure paths
```

## Historical failures / do not repeat

**TESTED FAILURE / DO NOT REPEAT:**

- Kahlua global `next()` was nil in a profile path. Use `pairs()` + explicit counting.
- Build CraftRecipe without a GameEntity SpriteConfig can appear in the menu but clicking Build produces no cursor.
- V2 LargeGate toolbar could show a complete ghost while click placement failed; do not resume speculative V2 patches.
- V3 generic `Base.LMION_OpeningParcel` without a WorldSprite broke both LargeGate placement frontends on `5841a976...`.
- Workshop/manual multipart pickup lifecycle is not the behavioral reference; Legacy delegates each LargeGate member to vanilla `pickUpMoveableInternal()`.
- A successful placement log is not proof of parcel consumption.
- Re-resolving a selected floor parcel from `item:getWorldItem()` after placement can lose the exact world object that must be removed; retain the selected `IsoWorldInventoryObject` through the transaction.
- Do not add batch IDs/pickup-session pairing to LargeGate or Garage stock.
- Garage synthetic L3 SpriteGrid is a technical Moveables adapter only; do not use it as the actual variable-chain pickup footprint.
- A custom `ISMoveablesAction` derivative must provide the normal Moveables context expected by vanilla (`moveProps` and related origin fields) if it inherits vanilla start/sound behavior.

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
- LargeGate segment-specific item + WorldSprite transport;
- LargeGate pickup through vanilla physical-member lifecycle;
- LargeGate toolbar and inventory/right-click replacement;
- LargeGate mixed inventory/floor parcel lookup in either Part1/Part2 arrangement;
- LargeGate exact floor-parcel consumption after successful placement;
- LargeGate per-parcel HP/maxHP restoration;
- functional canonical `IsoDoor` LargeGate leaf after replacement;
- Garage Green Build L3/L6;
- Garage Green pickup L3/L6 with requirements met/bypassed;
- Garage Green inventory replacement;
- Garage variable +/- width selection and successful placement;
- Garage placement action after Moveables sound-context correction.

**IMPLEMENTED BUT TEST STILL REQUIRED:**

- LargeGate Build runtime;
- Garage broader family/resource/stock/HP/floor/toolbar matrix listed above.

**NOT YET VALIDATED BROADLY:**

- remaining Simple definitions;
- remaining Paired definitions;
- remaining FenceGate definitions;
- remaining Sliding definitions.

## Immediate next work

Continue Garage validation rather than redesigning it. Highest-value next checks are the stock transaction cases (L6 -> L3 surplus, mixed inventory/floor), HP/maxHP persistence and exact resource consumption outside Build cheat. After those pass, broaden across Garage families/orientations and then return to remaining API/catalog validation.
