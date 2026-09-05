# LMION V3 current state / conversation handoff

Last updated: 2026-09-05

This file is the canonical handoff for active V3 development in `Coudji/LMION_instable_research`.

## Repository roles

- `Coudji/LMION_instable_research` — active V3 development/research workspace. This is the only repository to modify during unstable V3 work.
- `Coudji/LMION_Legacy` — archaeology and behavioral oracle. `Legacy/Contents` wins when refactor-era behavior conflicts with validated behavior.
- separate clean LMION repository — reserved for release-quality history/source after V3 validation.

Do not modify the clean release repository or `PZMOD_LMION` unless explicitly requested.

## Local development layout

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

The user's local PZ Workshop checkout pulls this repository directly. Group runtime checkpoints so the user does not have to restart PZ repeatedly.

## Non-negotiable product/architecture rules

- One gameplay mod; official systems such as Pickup and Build are internal responsibilities, not optional submods.
- Every final LMION-managed opening is an `IsoDoor`.
- `IsoThumpable(isDoor)` is accepted only as source/vanilla/external input at a narrow compatibility boundary.
- HP/max HP survive pickup/replacement.
- Standard Simple doors require the correct standard frame.
- Supported LargeGate construction is split into logical leaves A and B; never rename those identities left/right.
- Paired uses explicit left/right members.
- Garage uses explicit START/MIDDLE/END geometry.
- One function = one identifiable responsibility; hooks are thin adapters; one file = one identifiable responsibility; one vanilla hook = one owner.
- No catch-all routers/managers/bridges and no speculative abstractions.
- Responsibility/layer first, family specialization second.

Canonical LargeGate/door decision: `Docs/Decisions/CanonicalDoorsAndLargeGates.md`.

## Development diagnostics

During unstable V3, targeted logs are welcome and may be removed/reduced before release.

Prefer logs at meaningful boundaries with stable context such as definition ID, entity ID, type, facing/member/leaf and failure reason. Avoid per-frame/per-tick spam unless diagnosing that exact loop.

## Data/API foundation

Foundation commit:

```text
5e7c117245f88f13b0e03d76f5cbb574982d230b
```

Public external entry point:

```lua
local LMION = require "LMION/API"
```

Supported semantic types:

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

Important foundation responsibilities:

```text
Definitions/Registry.lua       raw registrations + monotonic revision
Definitions/Validation.lua     public data shape only
Definitions/Resolver.lua       default/definition/extension resolution
Definitions/EntityIndex.lua    derived GameEntity -> definitionId index
PZ/WorldObjectIdentity.lua     object -> GameEntity full name
Services/DefinitionLookup.lua  lookup orchestration
Domain/DoorTypes.lua           semantic type vocabulary/frame consequence
```

## Complete built-in catalog

Main migration:

```text
94d935485ca5baaa4731615bef39b7846f13ba6f
```

Current built-in counts:

```text
23 defaults
72 concrete definitions
0 built-in extensions
```

Definitions:

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

**VALIDÉ EN JEU**:

```text
[LMION:DEV] definitions ready: 23 defaults, 72 definitions, 0 extensions
```

The catalog migration is complete. Revisit it only for a concrete defect/API requirement.

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

Sprite name is not primary identity.

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
Runtime/Moveables/DoorTransportIdentity.lua
Runtime/Moveables/SimpleDoorSprites.lua
Services/Moveables/SimpleDoorProfiles.lua
Services/Moveables/SimpleDoorFlatpack.lua
Services/Moveables/SimpleDoorPlacementFinalizer.lua
Services/Build/ConstructionDurability.lua
Services/Build/SimpleDoorFinalizer.lua
Hooks/Moveables/SimpleDoor.lua
server/LMION/Hooks/Build/SimpleDoor.lua
```

Research/control-point docs:

```text
Docs/Architecture/DoorRuntimeFoundation.md
Docs/Research/Architecture/DoorObjectAbstraction.md
Docs/Research/Moveables/VanillaMoveablesBehavior.md
Docs/Research/Moveables/SimpleMoveablesHook.md
Docs/Research/Moveables/FlatpackTransport.md
Docs/Research/Build/SimpleDoorBuildPilot.md
```

Important Lua pitfall already encountered: preserve `false` explicitly; do not use an `a and b or nil` idiom for `getNorth()` because W/facing false is meaningful.

## White Panel Door pilot — baseline validated

Pilot definition/entity:

```text
Doors.Wood.WhitePanelDoor
Base.WhitePanelDoor
```

On 2026-09-04, before the generic-flatpack refactor, the complete loop was **VALIDÉ EN JEU**:

```text
Build White Panel Door
-> LMION canonicalizes vanilla IsoThumpable result to IsoDoor
-> damage door
-> Pickup through vanilla Moveables boundary
-> inventory transport item
-> replace through Moveables
-> standard frame enforced
-> HP/max HP restored
-> final IsoDoor
```

User explicitly confirmed construction, pickup, replacement, frame enforcement and HP persistence.

Representative logs:

```text
[LMION:DEV] Simple Build finalizing: definition=Doors.Wood.WhitePanelDoor entity=Base.WhitePanelDoor representation=IsoThumpable
[LMION:DEV] canonical door ready: IsoDoor facing=W
[LMION:DEV] Simple Build finalized: definition=Doors.Wood.WhitePanelDoor representation=IsoDoor health=725 max=725
[LMION:DEV] Simple pickup state captured: definition=Doors.Wood.WhitePanelDoor health=725 max=725
[LMION:DEV] Simple placement finalized: definition=Doors.Wood.WhitePanelDoor sprite=fixtures_doors_01_0 health=725 max=725
```

This validates the shared Simple runtime architecture, not every Simple catalog definition.

## White Panel engine script convention

The previous three pilot files were consolidated into exactly one Build-facing file:

```text
media/scripts/WhitePanelDoor.txt
```

It now contains only the PZ engine data required for vanilla Build:

```text
xuiSkin / Build icon
UiConfig
CraftRecipe
SpriteConfig
```

The former technical `item LMION_WhitePanelDoor` block has been removed as part of the generic-flatpack pilot.

Build still needs `CraftRecipe` and `SpriteConfig` in `media/scripts`; these cannot simply be omitted in favor of late Lua definition data. The first pilot proved that a recipe can appear in the menu without SpriteConfig but clicking Build then produces no cursor. Restoring SpriteConfig fixed that path.

The catalog remains the semantic source of truth for durability, material/tool facts, geometry and LMION behavior. Script files should contain the strict engine minimum.

## Build icon / texture convention

Door Build/XUI icons are organized under:

```text
Contents/mods/LMION_DEV/42/media/textures/LMION/doors/
```

Individual PNG filenames do **not** use an `LMION_` prefix; the `LMION/` directory is the namespace.

Example:

```text
media/textures/LMION/doors/WhitePanelDoor.png
Icon = LMION/doors/WhitePanelDoor,
```

Bulk move/rename commit:

```text
97aaec3cdb2bf9e02b8f4a034b0fc8960bbd993f
```

White Panel script icon update:

```text
21bb91e6aaf6bc2149e3af2bd663c29b5bc6c780
```

These are Build/XUI visuals. Doors do not need separate per-door inventory icons because pickup transport is a flatpack.

## B42 translations / ZedScripts

Current translation source files:

```text
media/lua/shared/Translate/EN/ItemName.json
media/lua/shared/Translate/EN/IG_UI.json
```

`IG_UI.json` owns:

```text
IGUI_CraftingCategories_LMION -> LMION
```

`ItemName.json` now owns the generic transport item:

```text
Base.LMION_Flatpack -> Flatpack
```

If ZedScripts reports an existing translation key as missing after pull/edit, run:

```text
Ctrl+Shift+P -> ZedScripts: Reset Scripts Cache
```

This already resolved the user's false `INVALID_TRANSLATION_KEY` diagnostics on 2026-09-05.

## Generic flatpack transport — IMPLEMENTED, NOT YET VALIDATED

Product rule from the user:

> A picked-up door becomes a flatpack. The inventory object is not a visual copy of the door.

Research/implementation note:

```text
Docs/Research/Moveables/FlatpackTransport.md
```

Research commit:

```text
7c76e95fc125be859d3e867067f6e08c161739e4
```

B42.20.3 engine scripts contain the vanilla world model `Flatpack`, so V3 reuses it rather than shipping a duplicate model.

One generic engine item now exists:

```text
media/scripts/Flatpack.txt
Base.LMION_Flatpack
```

The script contains only generic engine facts:

```text
ItemType = base:moveable
Icon = default
fallback Weight = 1.0
WorldStaticModel = Flatpack
Tags = base:usedisplayname
```

The fallback weight is replaced at runtime from `definition.pickup.packages.weight`.

Transport identity is explicit modData:

```text
lmionDoorDefinitionId
```

owned by:

```text
Runtime/Moveables/DoorTransportIdentity.lua
```

Door HP/max HP remain owned by `DoorTransportState.lua`.

`Services/Moveables/SimpleDoorFlatpack.lua` prepares the generic parcel and verifies that the stored definition identity matches the current Simple profile before placement.

The previous accidental gate (“only definitions that happen to have a per-door script item become active”) has been replaced with an explicit temporary pilot gate:

```text
Doors.Wood.WhitePanelDoor only
```

Do not remove that gate until generic-flatpack runtime validation succeeds.

Generic-flatpack implementation commits:

```text
634477b60912d4afb3d0a5c3c0f3901be4ea3d78
a890e6e8461b4c99dcdd57ec87d1323d8eb0e811
f71949ccd9328b4a583fe9b8d4604b440acc4eb0
52e6478f28b682376227c6614fb2d4b4db8c94a9
d65bb39e003386e6db6e09ecaad0c7d1f8b9a467
5269fb6f012ac794efce7f1c128feeed9bfbb036
b6e225af4bb4bf62c5772072841ef78ef4a558bb
69dd3195fa95c633c994be225c6098332a50bc31
826193b142120f2492df41c9de7dd62d8206630f
```

Expected new pickup log:

```text
[LMION:DEV] Simple flatpack serialized: definition=Doors.Wood.WhitePanelDoor item=Base.LMION_Flatpack prepared=true
```

## Historical Simple runtime failure

**ÉCHEC TESTÉ / NE PAS REFAIRE**: `SimpleDoorProfiles.getSingleSkillLevel()` initially used global `next()` and Kahlua reported `Object tried to call nil in getSingleSkillLevel` during `OnLoadedTileDefinitions`.

The fix uses `pairs()` and explicit entry counting.

## Current validation status

**VALIDÉ EN JEU**:

- catalog 23/72/0;
- GameEntity reverse lookup;
- White Panel Build;
- canonical IsoDoor Build finalization;
- White Panel pickup/replacement using the former per-door technical item;
- N/W replacement behavior exercised;
- standard frame requirement;
- HP/max-HP persistence.

**IMPLEMENTED / NON VALIDÉ EN JEU**:

- replacement of per-door technical pickup item with `Base.LMION_Flatpack`;
- explicit flatpack definition identity;
- generic flatpack runtime weight;
- reuse of vanilla `Flatpack` world model.

**NOT YET BROADLY IMPLEMENTED/VALIDATED**:

- all Simple definitions;
- Paired;
- FenceGate;
- Sliding;
- Garage;
- LargeGate.

## Testing strategy

Do not request PZ restarts for pure helper/data slices.

Because the generic flatpack introduces/changes `media/scripts`, its first meaningful validation requires a **cold restart**. Use one combined checkpoint:

```text
Build White Panel Door
-> damage it
-> Pickup
-> verify inventory item is Flatpack / Base.LMION_Flatpack
-> replace it in correct standard frame
-> exercise N/W rotation
-> verify HP/max HP
-> verify final object still IsoDoor
```

If this passes, record it as `VALIDÉ EN JEU`, then remove the temporary White Panel-only profile gate and expand Simple support deliberately.

## Immediate next step

The generic-flatpack pilot is ready for the next integrated runtime checkpoint. Do not add more door families before validating this transport representation, because it changes the engine item identity used by the already-proven Simple loop.

After generic flatpack validation:

1. remove the explicit White Panel-only gate;
2. determine which Simple definitions can share the existing Moveables mechanics without additional engine scripts;
3. add the strict-minimum one-file-per-buildable-door `media/scripts/<Door>.txt` entries only where vanilla Build support is desired/required;
4. keep definition-derived behavior in Lua rather than duplicating it in scripts;
5. group the resulting Simple catalog expansion before the next runtime restart.

Before any new vanilla hook/family integration, read the relevant active `Docs/Research/` note and document any expensive new runtime discovery.
