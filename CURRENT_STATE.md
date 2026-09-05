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

## White Panel baseline — VALIDÉ EN JEU

Pilot:

```text
Doors.Wood.WhitePanelDoor
Base.WhitePanelDoor
Base.LMION_WhitePanelDoor
```

Validated loop on 2026-09-04:

```text
Build
-> vanilla IsoThumpable source
-> LMION canonical IsoDoor
-> damage
-> Pickup
-> transport item
-> replace
-> standard frame enforced
-> HP/max HP restored
-> final IsoDoor
```

User explicitly confirmed construction, pickup, replacement, N/W behavior, frame enforcement and HP persistence.

Material consumption was not validated because BuildCheat was active in that test.

Historical successful logs used the former Simple-specific hook names. The runtime code has since been structurally generalized; White Panel must be regression-tested once at the next cold-start checkpoint.

## Current single-tile runtime architecture

The already-proven 1x1 mechanism has now been generalized only where actual duplicate behavior exists.

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

`PairedDoorProfiles.lua` remains separate because its geometry has two entities/members. Its first pilot is explicitly gated to:

```text
Doors.Wood.BlueChurchDoubleDoor
```

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

The former `Hooks/Moveables/SimpleDoor.lua`, `Runtime/Moveables/SimpleDoorSprites.lua` and `Services/Moveables/SimpleDoorPlacementFinalizer.lua` were removed after their responsibilities were replaced by the single-tile equivalents.

### Metal Moveables tools

`Runtime/Moveables/ToolDefinitions.lua` restores the narrow Legacy tool definitions:

```text
LMIONMetalScrewdriver -> physical screwdriver, Perks.MetalWelding
LMIONMetalCrowbar     -> physical crowbar, Perks.MetalWelding
LMIONMetalHammer      -> physical hammer, Perks.MetalWelding
```

`SingleTileProfileFields` uses normal vanilla Screwdriver/Crowbar/Hammer for Woodwork profiles and these LMION variants when `MetalWelding` is the governing pickup skill.

This restored bridge is **HYPOTHÈSE / NON VALIDÉ** in V3 until the Brown Sliding pilot is exercised.

## Current single-tile Build architecture

Build now also has one owner:

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

The former Simple-specific Build hook/finalizer were removed so the vanilla methods still have one owner.

## Current implemented pilots

### Simple baseline

```text
Doors.Wood.WhitePanelDoor
media/scripts/WhitePanelDoor.txt
```

Status: baseline **VALIDÉ EN JEU** before hook generalization; regression pending.

### Paired pilot

```text
Doors.Wood.BlueChurchDoubleDoor
├─ Base.BlueChurchDoubleDoorLeft
└─ Base.BlueChurchDoubleDoorRight
media/scripts/BlueChurchDoubleDoor.txt
```

Behavior source:

- independent 1x1 leaves;
- left requires `DoubleDoor1` frame class;
- right requires `DoubleDoor2` frame class;
- separate transport items;
- separate Build recipes;
- canonical final `IsoDoor`.

Status: **HYPOTHÈSE / NON VALIDÉ**.

Research: `Docs/Research/Moveables/PairedDoorPilot.md`.

### FenceGate pilot

```text
FenceGates.Wood.SmallWhiteWoodenGate
media/scripts/SmallWhiteWoodenGate.txt
```

Behavior:

```text
no frame
pickup Woodwork 1 + crowbar
replacement hammer
package weight 7
```

`SpriteConfig.dontNeedFrame = true` is retained only as the PZ engine-time Build bridge.

Status: **HYPOTHÈSE / NON VALIDÉ**.

### Sliding pilot

```text
SlidingDoors.BrownSlidingGlassDoor
media/scripts/BrownSlidingGlassDoor.txt
```

Behavior:

```text
no frame
pickup MetalWelding 1 + crowbar
replacement hammer
package weight 20
Build MetalWelding 3
```

The V3 Build script follows the catalog material alternative:

```text
2 x [Base.MetalBar;Base.IronBar]
```

Status: **HYPOTHÈSE / NON VALIDÉ**.

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

## Translation / ZedScripts

EN item keys currently include the four pilot openings and both Blue Church leaves.

If ZedScripts shows stale `INVALID_TRANSLATION_KEY` diagnostics after pull:

```text
Ctrl+Shift+P -> ZedScripts: Reset Scripts Cache
```

This already resolved the issue once.

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
- White Panel Build/canonicalization;
- White Panel pickup/replacement on the pre-generalization Simple hook;
- N/W replacement;
- standard frame requirement;
- HP/max-HP persistence.

**IMPLEMENTED / TEST EN JEU REQUIS**:

- generalized single-tile Moveables hook owner;
- generalized single-tile Build hook owner;
- White Panel regression through the new owners;
- Blue Church Paired pilot;
- Small White Wooden FenceGate pilot;
- Brown Sliding Glass Door pilot;
- restored MetalWelding Moveables tool definitions.

**NOT YET IMPLEMENTED/VALIDATED BROADLY**:

- full Simple catalog activation;
- all Paired definitions;
- all FenceGate definitions;
- all Sliding definitions;
- Garage V3 runtime;
- LargeGate V3 runtime.

## Next runtime checkpoint

Because this expansion changes hook topology and adds three new `media/scripts` files, use **one cold restart** for the complete checkpoint.

Test together:

```text
1. White Panel regression
   Build -> Pickup -> replace
   standard frame
   N/W
   HP/max HP

2. Blue Church Paired
   left accepted only on DoubleDoor1 frame
   right accepted only on DoubleDoor2 frame
   each leaf Build/Pickup/replace independently
   N/W
   HP/max HP

3. Small White Wooden FenceGate
   Build without frame
   Pickup with crowbar
   replace with hammer without frame
   N/W
   HP/max HP

4. Brown Sliding Glass Door
   Build without frame
   Pickup/replace through MetalWelding tool definitions
   N/W
   HP/max HP
```

Capture relevant `[LMION:DEV]` lines if any branch fails. Do not add further families before resolving failures from this checkpoint.

After this checkpoint passes, record exactly which pilot mechanics are `VALIDÉ EN JEU`, then decide whether to expand the remaining 1x1 catalog or move to Garage/LargeGate. Package appearance remains deferred regardless.
