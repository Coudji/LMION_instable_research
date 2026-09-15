# LMION V3 current state / conversation handoff

Last updated: 2026-09-15

This file is the canonical short handoff for active V3 development in `Coudji/LMION_instable_research`. Detailed archaeology and failed experiments remain in `Docs/Research/`; active architectural contracts live in `Docs/Architecture/` and `Docs/Decisions/`.

## Repository and safety checkpoints

Active repository/branch:

```text
Coudji/LMION_instable_research
main
```

Known-good backup points:

```text
backup-2026-09-14-pre-reorganization
    -> before the major Build/Moveables/Common organization pass

backup-2026-09-15-pre-polish
    -> gameplay-stable state immediately before naming/documentation polish
    -> 69fc170f635aae4a9865ffbc35ea75c4a2aeed32

backup-2026-09-15-pre-garage-width-rename
    -> after architecture/naming polish, before Garage length->width terminology cleanup
    -> 8578a2b0d3f03aadf5cbc18419a39fbb2e6ce224
```

`Coudji/LMION_Legacy` remains the behavioral oracle when V3 behavior is uncertain. Do not modify Legacy unless explicitly requested.

## Core V3 rules

LMION V3 is one gameplay mod. Build and Moveables are subsystems, not mutually dependent addons.

Architectural dependency rule:

```text
                 Services/Common
                /               \
             Build             Moveables
              |                    |
     family-specific code   family-specific code
```

Build must not depend on Moveables to understand an opening, and Moveables must not depend on Build. Neutral identity/geometry/placement rules belong in `Services/Common`.

No file should be moved between `client`, `server` and `shared` merely for organization. Source remains human-readable.

## Public API / definitions

External addons use:

```lua
local LMION = require "LMION/API"
```

Current built-in data:

```text
23 defaults
72 definitions
0 built-in extensions
```

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

Definitions remain semantic/data-driven. Do not restore redundant public frame/topology implementation fields. Paired membership comes from geometry; LargeGate logical leaves are stable A/B.

Full strict public-schema validation remains deferred until the API shape is complete.

## Canonical world representation

Every final LMION-managed opening is an `IsoDoor`.

`IsoThumpable(isDoor)` may be accepted at narrow vanilla/external boundaries, but is not a final LMION representation.

Pickup/replacement preserves transported durability. `Runtime/DoorState.lua` and `Runtime/DoorDurability.lua` own normalized world state/durability behavior.

## Current shared service layout

```text
Services/Common/
├─ Garage/
│  └─ Profiles.lua
├─ LargeGate/
│  ├─ Profiles.lua
│  ├─ Members.lua
│  └─ PlacementSpace.lua
└─ SingleTileDoor/
   └─ Placement.lua
```

The former flat `*DefinitionProfiles.lua`, `LargeGateMembers.lua`, `LargeGatePlacementSpace.lua` and `SingleTileDoorPlacement.lua` paths were removed after consumers were migrated.

The old Moveables `LargeGate/WorldState.lua` partner/incoherent placement model was also removed.

## Single-tile behavior — representative in-game validation

Representative tested definitions include:

```text
Doors.Wood.WhitePanelDoor
Doors.Wood.BlueChurchDoubleDoor
FenceGates.Wood.SmallWhiteWoodenGate
SlidingDoors.BrownSlidingGlassDoor
```

Validated as applicable:

```text
Build
pickup
replacement
N/W orientation
Simple standard-frame requirement
Paired matching frame-side requirement
FenceGate / Sliding no-frame placement
HP/maxHP transport persistence
canonical final IsoDoor
```

Recent regression testing specifically reconfirmed Simple, Paired and FenceGate behavior after the architecture reorganization.

## Inventory placement versus toolbar

The inventory/right-click path is intentionally separate from the Moveables toolbar.

```text
client/Hooks/Moveables/InventoryPlacement.lua
```

Routing:

```text
single-tile parcel -> server/LMION/Moveables/DoorInventoryCursor.lua
LargeGate parcel  -> server/LMION/Moveables/DoorInventoryCursor.lua
Garage parcel     -> server/LMION/Moveables/GarageCursor.lua
other Moveable    -> vanilla
```

The dedicated door inventory cursor preserves `R` rotation and does not activate the toolbar.

Garage inventory placement remains variable-width with its +/- controls. Garage toolbar placement intentionally remains fixed width 3.

## Shared Moveables engine hook

`shared/LMION/Hooks/Moveables/SpriteProps.lua` owns the common `ISMoveableSpriteProps` boundary used by single-tile doors, LargeGate and Garage.

The old filename `Hooks/Moveables/SingleTileDoor.lua` was removed because the hook had become cross-family.

Multipart vanilla-cursor rendering is owned by:

```text
server/LMION/Hooks/Moveables/MultipartGhost.lua
```

This is a rendering hook, not a cursor implementation.

## LargeGate model

LargeGate is permanently modeled as:

```text
LargeGate
├─ leaf A
│  ├─ physical member 1
│  └─ physical member 2
└─ leaf B
   ├─ physical member 1
   └─ physical member 2
```

Pickup/replacement is per leaf and uses two physical parcels. Inventory and nearby-floor parcels can be mixed; Part1/Part2 are resolved independently and the exact selected floor world object is consumed. The reconstructed leaf is canonical `IsoDoor` and transported HP/maxHP follows the selected parcels.

### LargeGate placement contract — validated in game

Placement/build does **not** search for or infer a partner leaf. A candidate A/B leaf is always planned closed; PZ owns normal double-door grouping once the correct native members exist.

`Services/Common/LargeGate/PlacementSpace.lua` derives the complete native 2x2 swing square. The candidate is rejected when:

```text
its normal closed member placement is invalid
one of the four swing cells has a solid/tree/vehicle obstruction
a wall/window/door/fence-like barrier cuts through the swing square
its swing square overlaps the swing square of any existing LMION LargeGate
```

This protects both the candidate and existing LargeGate leaves. Invalid inventory positions remain visible as a red ghost instead of disappearing.

The reverse rule is intentionally **not** imposed on other families. A Garage, FenceGate or other later construction may block an existing LargeGate. This can be accidental or an intentional defensive arrangement.

Decision: `Docs/Decisions/LargeGatePlacementSpace.md`.

### LargeGate toggle HP — still test pending

`Runtime/LargeGateToggleState.lua` contains the state-preservation path around PZ's internal `ToggleDoor()` recreation boundary.

Do not describe normal open/close HP preservation as validated until a dedicated current in-game test confirms damaged HP survives both opening and closing.

## Garage width contract

For Garage, **width** is the canonical term for the variable number of occupied tiles, regardless of N/W facing. Do not use `length` for this concept in active code or documentation.

Current width vocabulary:

```text
Domain/GarageWidthPolicy.lua
Services/Build/Garage/WidthState.lua
client/LMION/UI/Build/GarageWidthSelector.lua
GarageBuild.DefaultWidth / MinWidth / normalizeWidth
lmionGarageWidth
plan.width
SandboxVars.LMION.GarageMaxWidth
SandboxVars.LMION.UnlimitedGarageWidth
GarageWidthDecrease / GarageWidthIncrease
```

Core Garage behavior previously validated in game includes variable-width Build, pickup/replacement, N/W behavior, resource scaling, and variable inventory placement.

Build services:

```text
Services/Build/Garage/Build.lua
Services/Build/Garage/FaceProxy.lua
Services/Build/Garage/Finalizer.lua
Services/Build/Garage/WidthState.lua
Services/Build/Garage/Requirements.lua
```

Client UI ownership:

```text
client/LMION/UI/Build/GarageWidthSelector.lua
client/LMION/Hooks/Build/Garage.lua
client/LMION/Keybinds/GaragePlacement.lua
```

The intentional frontend difference remains:

```text
inventory context -> variable Garage width
toolbar Moveables -> fixed width 3
```

Width policy:

```text
minimum width = 2
default maximum = 6
configurable maximum = 6..12
UnlimitedGarageWidth = no LMION width cap
```

## Static PZ script rule — validated by startup failure/fix

Vanilla GameEntities must **not** be statically redeclared by LMION.

The duplicate-tile startup failure demonstrated that repeating a vanilla entity/SpriteConfig in an LMION script merges into the vanilla entity and can invalidate it.

Current rule:

```text
vanilla script owns vanilla GameEntity
LMION definitions/runtime may reference or adapt it
LMION static scripts may declare LMION items/custom entities only
```

For vanilla single doors/fence gates, cleaned script files retain only their LMION transport item declarations.

For `DoubleDoor`, `DoubleFenceGate` and `DoubleWireGate`, LMION static files retain parcel items and the custom B entity; the vanilla A entity/style is not redeclared. `Runtime/Build/VanillaLargeGateLeafPreparation.lua` performs the supported leaf-A adaptation at the validated runtime lifecycle boundary instead.

## Startup status

After the vanilla-script cleanup, phase-0 startup was validated:

```text
23 defaults, 72 definitions, 0 extensions
LargeGate Build bridge: 12/12 leaf entities
no LMION Tile duplicate
no LMION module-not-found
no LMION Lua startup error
```

## 2026-09-15 architecture/naming polish

A behavior-neutral polish pass was performed only after the gameplay paths above appeared stable.

Main changes:

```text
Common services grouped by family
cross-family SpriteProps hook named by responsibility
inventory context hook named by responsibility
multipart ghost hook moved from misleading cursor classification
obsolete LargeGate partner-state service removed
Garage Build filenames shortened inside their family folder
Garage variable dimension standardized on width
architecture/decision/current-state docs refreshed
```

No Catalog/Defaults semantic data was changed by this polish, and no file changed realm.

After this naming pass, run a short cold-start smoke test rather than repeating the entire gameplay matrix immediately:

```text
startup
one 1x1 inventory replacement + R
one LargeGate replacement + blocked-swing preview
one Garage Build width change
one Garage variable inventory placement
```

Escalate to the full regression matrix only if one of those fails.
