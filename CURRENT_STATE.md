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
- `IsoThumpable(isDoor)` is accepted only as a source/vanilla/external compatibility representation;
- HP/max HP survive pickup/replacement;
- Simple standard framed doors require the matching standard frame;
- LargeGate uses stable leaf identity A/B, never left/right;
- Paired uses explicit left/right members;
- Garage uses explicit START/MIDDLE/END geometry;
- one function = one identifiable responsibility;
- one file = one identifiable responsibility;
- hooks stay thin and one vanilla boundary has one owner;
- no catch-all routers/managers/bridges;
- no speculative abstractions before proven duplicate behavior exists.

Canonical decision doc: `Docs/Decisions/CanonicalDoorsAndLargeGates.md`.

## Development diagnostics

Targeted DEV logs are welcome during unstable development. Prefer stable context such as definitionId, entityId, type, facing/member/leaf and failure reason. Avoid per-frame/per-tick spam unless diagnosing that exact loop.

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

Important foundation files:

```text
Definitions/Registry.lua
Definitions/Validation.lua
Definitions/Resolver.lua
Definitions/EntityIndex.lua
PZ/WorldObjectIdentity.lua
Services/DefinitionLookup.lua
Domain/DoorTypes.lua
```

## Built-in catalog

Main migration:

```text
94d935485ca5baaa4731615bef39b7846f13ba6f
```

Current counts:

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

Do not revisit catalog migration without a concrete defect/API need.

## GameEntity reverse lookup

Research:

```text
5b45221c1893ff876f79d2a9bbc9f94ce046da94
```

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

**VALIDÉ EN JEU** as part of the Simple pilot:

```text
[LMION:DEV] entity index ready: 77 mappings; Base.WhitePanelDoor -> Doors.Wood.WhitePanelDoor
```

Sprite name is not primary world-object identity.

## Shared Simple 1x1 runtime foundation

Important files:

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

Important Lua pitfall already encountered: preserve `false` explicitly; do not use `a and b or nil` for `getNorth()` because W/facing false is meaningful.

Research/control-point docs:

```text
Docs/Architecture/DoorRuntimeFoundation.md
Docs/Research/Architecture/DoorObjectAbstraction.md
Docs/Research/Moveables/VanillaMoveablesBehavior.md
Docs/Research/Moveables/SimpleMoveablesHook.md
Docs/Research/Build/SimpleDoorBuildPilot.md
```

## White Panel Door pilot — VALIDÉ EN JEU

Pilot:

```text
Doors.Wood.WhitePanelDoor
Base.WhitePanelDoor
Base.LMION_WhitePanelDoor
```

Validated loop:

```text
Build White Panel Door
-> vanilla initially creates IsoThumpable
-> LMION canonicalizes to IsoDoor
-> damage door
-> Pickup through vanilla Moveables
-> Base.LMION_WhitePanelDoor transport item
-> replace through Moveables
-> standard frame enforced
-> HP/max HP restored
-> final IsoDoor
```

User explicitly confirmed:

- construction works;
- pickup works;
- replacement works;
- N/W behavior works;
- standard-frame requirement is respected;
- HP/max HP persist.

Representative logs:

```text
[LMION:DEV] Simple Build finalizing: definition=Doors.Wood.WhitePanelDoor entity=Base.WhitePanelDoor representation=IsoThumpable
[LMION:DEV] canonical door ready: IsoDoor facing=W
[LMION:DEV] Simple Build finalized: definition=Doors.Wood.WhitePanelDoor representation=IsoDoor health=725 max=725
[LMION:DEV] Simple pickup state captured: definition=Doors.Wood.WhitePanelDoor health=725 max=725
[LMION:DEV] Simple transport item serialized: definition=Doors.Wood.WhitePanelDoor item=Base.LMION_WhitePanelDoor
[LMION:DEV] Simple placement finalized: definition=Doors.Wood.WhitePanelDoor sprite=fixtures_doors_01_0 health=725 max=725
```

This validates the shared Simple runtime architecture, not every Simple definition.

## White Panel engine script convention

The pilot uses one consolidated file:

```text
media/scripts/WhitePanelDoor.txt
```

It currently contains:

```text
item LMION_WhitePanelDoor
xuiSkin
entity WhitePanelDoor
    UiConfig
    CraftRecipe
    SpriteConfig
```

This is intentionally one file per opening rather than separate `_Item`, `_Build`, `_Entity` files.

The script should contain only data PZ needs before Lua. The catalog remains the semantic source of truth for LMION behavior.

Build still requires `CraftRecipe` and `SpriteConfig` in `media/scripts`. The first Build pilot proved that a recipe can appear in the menu without SpriteConfig while clicking Build silently creates no cursor. Restoring SpriteConfig fixed that path.

## Build icon / texture convention

Build/XUI door icons live under:

```text
Contents/mods/LMION_DEV/42/media/textures/LMION/doors/
```

PNG filenames do not use an `LMION_` prefix because `LMION/` is already the namespace.

Example:

```text
media/textures/LMION/doors/WhitePanelDoor.png
Icon = LMION/doors/WhitePanelDoor,
```

These assets are Build/XUI visuals. Transport-item appearance is deliberately deferred.

## B42 translations / ZedScripts

Current EN translation files include:

```text
media/lua/shared/Translate/EN/ItemName.json
media/lua/shared/Translate/EN/IG_UI.json
```

Current relevant keys:

```text
Base.LMION_WhitePanelDoor -> White Panel Door
IGUI_CraftingCategories_LMION -> LMION
```

If ZedScripts reports an existing translation key as missing after pull/edit:

```text
Ctrl+Shift+P -> ZedScripts: Reset Scripts Cache
```

This already resolved the user's false `INVALID_TRANSLATION_KEY` diagnostics.

## Transport appearance / flatpack — DEFERRED

Do **not** work on package/flatpack appearance now.

The user decided on 2026-09-05 that this is premature. The correct time to decide transport visuals/identity is **after functional V3 runtime exists for LargeGate and Garage**.

Current rule:

```text
function first
-> multipart runtime first
-> package appearance later
```

A short-lived generic-flatpack experiment introduced:

```text
Base.LMION_Flatpack
Runtime/Moveables/DoorTransportIdentity.lua
Services/Moveables/SimpleDoorFlatpack.lua
```

and stored definition identity in modData. It was **never tested in game** and has now been removed.

The code has been restored to the previously validated White Panel transport path:

```text
Base.LMION_WhitePanelDoor
```

Do not resume the generic-flatpack experiment by default.

Research note:

```text
Docs/Research/Moveables/FlatpackTransport.md
```

The note now records the decision as deferred.

## Current validation status

**VALIDÉ EN JEU**:

- catalog 23/72/0;
- GameEntity reverse lookup;
- White Panel Build;
- canonical IsoDoor Build finalization;
- White Panel pickup/replacement with `Base.LMION_WhitePanelDoor`;
- N/W replacement behavior;
- standard frame requirement;
- HP/max-HP persistence.

**NOT YET BROADLY IMPLEMENTED/VALIDATED**:

- all Simple definitions;
- Paired;
- FenceGate;
- Sliding;
- Garage;
- LargeGate.

## Historical failures / do not repeat

`SimpleDoorProfiles.getSingleSkillLevel()` initially used global `next()` and Kahlua reported `Object tried to call nil in getSingleSkillLevel` during `OnLoadedTileDefinitions`.

Fix: use `pairs()` and explicit entry counting.

LargeGate V2 toolbar placement had a complete ghost but clicking did not place the gate. The exact cancellation boundary was never instrumented. Do not resume speculative patching there; recover Legacy behavior and instrument the narrow vanilla boundary when V3 reaches LargeGate.

## Testing strategy

Do not ask for a PZ restart after each pure Lua/data slice.

The restored White Panel path is the already validated path, so **no new runtime test is required solely for undoing the untested generic-flatpack experiment**.

New `media/scripts` topology still requires a cold restart at the next meaningful integrated checkpoint; group several related changes first.

## Immediate next step

Continue functional runtime work rather than package appearance.

The next work should expand opening behavior in a controlled order. For Simple expansion, avoid assuming every definition is automatically Build-ready: distinguish existing-world pickup/replacement support from vanilla Build engine-script requirements.

Do not revisit flatpack/package visuals until functional LargeGate and Garage V3 behavior exists and their real parcel constraints are known.
