# LMION V3 current state / conversation handoff

Last updated: 2026-09-05

This file is the canonical handoff for active V3 development in `Coudji/LMION_instable_research`.

## Repository roles

- `Coudji/LMION_instable_research` — only active V3 development repository.
- `Coudji/LMION_Legacy` — archaeology and behavioral oracle; `Legacy/Contents` wins over failed/refactor-era behavior.
- separate clean LMION repository — reserved for later release-quality history/source.
- do not touch `PZMOD_LMION` unless explicitly requested.

Local dev identity:

```text
Workshop title: Let Me In... Or Not [DEV]
Mod id:         LMION_DEV
Mod folder:     Contents/mods/LMION_DEV
```

The user's local Workshop checkout pulls this repository directly. Avoid unnecessary PZ restarts; group changes into meaningful runtime checkpoints.

## Non-negotiable architecture/product rules

- one gameplay mod; Pickup, Build and future official systems are internal responsibilities;
- every final LMION-managed opening is an `IsoDoor`;
- `IsoThumpable(isDoor)` is accepted only as source/vanilla/external input at a narrow compatibility boundary;
- HP/max HP survive pickup/replacement;
- Simple standard framed doors require a matching standard frame;
- Paired uses explicit independent `left` / `right` 1x1 leaves and matching paired frame sides;
- FenceGate and Sliding require no frame;
- LargeGate uses stable leaf identity A/B, never left/right;
- Garage uses explicit START/MIDDLE/END geometry;
- one function = one identifiable responsibility;
- one file = one identifiable responsibility;
- hooks stay thin and one vanilla boundary has one owner;
- no catch-all routers/managers/bridges;
- no speculative abstractions before proven duplicate behavior exists.

Canonical LargeGate/door decision: `Docs/Decisions/CanonicalDoorsAndLargeGates.md`.

## Development diagnostics

Targeted DEV logs are welcome. Prefer stable context such as definitionId, entityId, type, facing/member/leaf and failure reason. Avoid per-frame/per-tick spam unless diagnosing that exact loop.

## Data/API foundation

Foundation commit:

```text
5e7c117245f88f13b0e03d76f5cbb574982d230b
```

External addons use:

```lua
local LMION = require "LMION/API"
```

Supported semantic `doorType` values:

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

Do not restore redundant public `frame` fields.

## Built-in catalog

Main migration:

```text
94d935485ca5baaa4731615bef39b7846f13ba6f
```

Current built-in count:

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

**VALIDÉ EN JEU**:

```text
[LMION:DEV] definitions ready: 23 defaults, 72 definitions, 0 extensions
```

## GameEntity reverse lookup

Implementation:

```text
4ef94ad72b5f72fb1aaff1b8ea9e34962af571ef
```

Identity chain:

```text
world object
-> object:getEntityScript():getFullName()
-> EntityIndex
-> definitionId
-> effective definition
```

**VALIDÉ EN JEU**:

```text
[LMION:DEV] entity index ready: 77 mappings; Base.WhitePanelDoor -> Doors.Wood.WhitePanelDoor
```

Sprite name is not primary world-object identity.

## Current single-tile runtime architecture

The proven 1x1 mechanism is shared only where behavior is genuinely identical.

### PZ/runtime responsibilities

```text
PZ/DoorObject.lua
PZ/DoorSprite.lua
PZ/DoorFrame.lua
PZ/StandardDoorFrame.lua
PZ/PairedDoorFrame.lua
PZ/PlacedDoor.lua
PZ/BuiltDoor.lua
Runtime/DoorDurability.lua
Runtime/DoorState.lua
Runtime/DoorPlacement.lua
Runtime/CanonicalDoor.lua
Runtime/Moveables/DoorTransportState.lua
Runtime/Moveables/SingleTileDoorSprites.lua
Runtime/Moveables/ToolDefinitions.lua
```

`PZ/DoorFrame.lua` classifies/query frame structure only:

```text
standard
paired-left  -> DoubleDoor1
paired-right -> DoubleDoor2
```

Semantic Paired definitions still expose only `left` / `right`; no public frame-side implementation field was added.

Placement rules:

```text
Simple    -> common safety checks + standard frame
Paired    -> common safety checks + matching paired frame side
FenceGate -> common safety checks, no frame
Sliding   -> common safety checks, no frame
```

### Moveables profile responsibilities

```text
Services/Moveables/SingleTileProfileFields.lua
Services/Moveables/SingleEntityDoorProfiles.lua
Services/Moveables/PairedDoorProfiles.lua
Services/Moveables/SingleTileDoorProfiles.lua
Services/Moveables/SingleTileDoorMoveProps.lua
Services/Moveables/SingleTileDoorPlacement.lua
Services/Moveables/SingleTileDoorPlacementFinalizer.lua
```

`SingleEntityDoorProfiles.lua` covers the genuinely identical one-entity N/W shape:

```text
Simple
FenceGate
Sliding
```

A definition is activated by that provider only if its matching transport script item exists. This currently activates only the explicit pilots, not the entire catalog.

`PairedDoorProfiles.lua` remains separate because its geometry has two entities/members.

### One Moveables hook owner

There is exactly one owner for the shared vanilla methods:

```text
Hooks/Moveables/SingleTileDoor.lua
```

It owns:

```text
ISMoveableSpriteProps.new
hasFaces / getFaces
pickUpMoveableInternal
instanceItem
canPlaceMoveableInternal
placeMoveableInternal
```

Unknown/non-LMION objects return to the previous vanilla implementation.

### Metal Moveables tools

`Runtime/Moveables/ToolDefinitions.lua` restores the narrow Legacy tool definitions:

```text
LMIONMetalScrewdriver -> physical screwdriver, Perks.MetalWelding
LMIONMetalCrowbar     -> physical crowbar, Perks.MetalWelding
LMIONMetalHammer      -> physical hammer, Perks.MetalWelding
```

The Brown Sliding pilot exercised this bridge successfully on 2026-09-05.

## Current single-tile Build architecture

Build has one owner:

```text
server/LMION/Hooks/Build/SingleTileDoor.lua
```

It owns only:

```text
ISBuildIsoEntity.isValid
ISBuildIsoEntity.isValidPerSquare
ISBuildIsoEntity.setInfo
```

Supporting services:

```text
Services/Build/SingleTileDoorBuildProfile.lua
Services/Build/SingleTileDoorFinalizer.lua
Services/Build/ConstructionDurability.lua
```

Unknown/non-LMION builds preserve vanilla behavior. Supported builds use GameEntity -> EntityIndex -> effective definition, add the LMION placement rule, let vanilla create the source, then canonicalize to `IsoDoor` and apply definition-owned durability.

## Single-tile integrated checkpoint — VALIDÉ EN JEU

On 2026-09-05 the user cold-start tested all four current pilots and reported all four functional. There are still minor details/polish to revisit later, but no blocking runtime defect was observed.

### Simple regression

```text
Doors.Wood.WhitePanelDoor
media/scripts/WhitePanelDoor.txt
```

Validated again through the generalized single-tile hook owners:

```text
Build
Pickup
replacement
standard-frame enforcement
N/W path functional
HP/max-HP persistence
```

### Paired pilot

```text
Doors.Wood.BlueChurchDoubleDoor
├─ Base.BlueChurchDoubleDoorLeft
└─ Base.BlueChurchDoubleDoorRight
media/scripts/BlueChurchDoubleDoor.txt
```

Validated functional:

```text
independent left/right leaves
matching paired frame behavior
Build/Pickup/replacement path
N/W path functional
HP/max-HP persistence
```

This validates the Blue Church pilot and Paired 1x1 architecture, not every Paired definition.

Research: `Docs/Research/Moveables/PairedDoorPilot.md`.

### FenceGate pilot

```text
FenceGates.Wood.SmallWhiteWoodenGate
media/scripts/SmallWhiteWoodenGate.txt
```

Validated functional:

```text
Build without frame
Pickup/replacement without frame
N/W path functional
HP/max-HP persistence
```

### Sliding pilot

```text
SlidingDoors.BrownSlidingGlassDoor
media/scripts/BrownSlidingGlassDoor.txt
```

Validated functional:

```text
Build without frame
MetalWelding Moveables tool bridge
Pickup/replacement
N/W path functional
HP/max-HP persistence
```

FenceGate/Sliding research: `Docs/Research/Moveables/UnframedSingleTilePilots.md`.

## Script convention

One engine script file per opening/family, not separate `_Item`, `_Build`, `_Entity` files.

Current examples:

```text
WhitePanelDoor.txt
BlueChurchDoubleDoor.txt
SmallWhiteWoodenGate.txt
BrownSlidingGlassDoor.txt
```

A Paired family file contains both leaf item/entity declarations because they belong to one opening family.

Scripts keep only parse-time data PZ genuinely needs: transport item declaration, XUI, CraftRecipe, SpriteConfig. LMION definition data remains authoritative for semantic type, durability, geometry and gameplay facts.

Build/XUI icons live under:

```text
media/textures/LMION/doors/
```

with no redundant `LMION_` filename prefix.

## Transport appearance / flatpack — DEFERRED

Do **not** work on package/flatpack appearance now.

The user decided on 2026-09-05 that this must wait until functional V3 Garage and LargeGate runtime exists and their real parcel constraints are known.

A short-lived generic `Base.LMION_Flatpack` experiment was never tested and was removed. Current technical transport items remain intentionally plain (`Icon = default`).

Research note: `Docs/Research/Moveables/FlatpackTransport.md`.

## Historical failures / do not repeat

**ÉCHEC TESTÉ / NE PAS REFAIRE**:

- Kahlua global `next()` was nil in the Moveables profile path. Use `pairs()` + explicit counting.
- Build CraftRecipe without a GameEntity SpriteConfig could appear in the menu but clicking Build produced no cursor. SpriteConfig is required for this vanilla Build path.
- LargeGate V2 toolbar ghost could appear complete while click placement failed; the exact cancellation boundary was never instrumented. Do not resume speculative patches there.

## Validation status

**VALIDÉ EN JEU**:

- catalog 23/72/0;
- GameEntity reverse lookup;
- generalized single-tile Moveables hook owner;
- generalized single-tile Build hook owner;
- White Panel regression through generalized owners;
- Blue Church Paired pilot;
- Small White Wooden FenceGate pilot;
- Brown Sliding Glass Door pilot;
- restored MetalWelding Moveables tool definitions through Sliding pilot;
- N/W behavior for current pilots;
- frame/no-frame contracts for current pilots;
- HP/max-HP persistence for current pilots.

**FUNCTIONAL BUT DETAILS/POLISH STILL OPEN**:

- all four current pilots may have minor behavior/UI/detail adjustments before release-quality freeze.

**NOT YET IMPLEMENTED/VALIDATED BROADLY**:

- full Simple catalog activation;
- all Paired definitions;
- all FenceGate definitions;
- all Sliding definitions;
- Garage V3 runtime;
- LargeGate V3 runtime.

## Immediate next direction

The single-tile architecture is now runtime-proven across all four semantic 1x1 families represented by current pilots.

Next development can proceed without another immediate restart. Prefer one of these controlled expansions:

```text
A. activate remaining 1x1 catalog definitions in batches using the validated architecture
B. move to the first multipart family (Garage or LargeGate)
```

Do not revisit package appearance yet. Preserve one-hook ownership and keep family-specific topology/rules outside the shared vanilla boundary owners.