# LMION V3 current state / conversation handoff

Last updated: 2026-09-17

This file is the canonical short handoff for active V3 development in `Coudji/LMION_instable_research`. Detailed archaeology and failed experiments remain in `Docs/Research/`; active architectural contracts live in `Docs/Architecture/` and `Docs/Decisions/`.

A public-facing wiki prototype now lives under `Docs/WikiPrototype/`. It is intentionally separate from the internal technical documentation and is meant to prototype the future user/modder wiki that will eventually accompany the distributed `Coudji/PZMOD_LMION` repository. Do not modify the distribution repository unless explicitly requested.

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

backup-2026-09-15-pre-moveables-presentation
    -> before the current V3 animation/sound/tooltip presentation pass
    -> 34b3c41cab0b41c7f3fab527336fbaee7ef7c1de
```

`Coudji/LMION_Legacy` is not the preferred source for current presentation work. `Workshop/Contents/mods/LMION_Pickup` was used as the behavioral reference for the previously solved Moveables animation/equipment sequencing problems. Do not modify Legacy or Workshop unless explicitly requested.

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

Transport parcels persist that state through `Runtime/Moveables/DoorTransportState.lua` using `lmionDoorHealth` / `lmionDoorMaxHealth`.

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

Dedicated inventory cursors set:

```text
noNeedHammer = true
skipBuildAction = true
skipWalk2 = true
```

The two skip flags are important: `ISBuildingObject` must not queue a vanilla `ISBuildAction` before the LMION Moveables placement action. Without them, the character begins a vanilla strike/sound with the currently held item, then equips the definition-selected tool and starts the actual placement action.

## Moveables action presentation — validated in game

Definitions remain authoritative for the gameplay tool and governing skill. `Services/Moveables/ActionPresentation.lua` only maps that contract to presentation assets; it does not infer a tool from `frame` or `doorType`.

Current animation mapping:

```text
screwdriver pickup/place -> LMION_ScrewdriverHinge
crowbar pickup           -> LMION_CrowbarPickupLow
hammer place             -> LMION_HammerPlace
```

Current material-aware sound mapping:

```text
Woodwork + crowbar      -> BeginRemoveBarricadePlankCrowbar
MetalWelding + crowbar  -> BuildMetalStructureSmall
Woodwork + hammer       -> Hammering
MetalWelding + hammer   -> BuildMetalStructureSmall
```

The screwdriver intentionally keeps the normal/configured Moveables sound; no LMION material override is required there.

`LMION_HammerPlace` reuses the vanilla `Bob_IdleHammering` motion under an LMION-specific `PerformingAction`, rather than using the vanilla `Build` action. This avoids the animation-event hammer sound being layered over the LMION material-aware sound.

`client/LMION/Hooks/Moveables/ActionPresentation.lua` owns runtime integration with `ISMoveablesAction`: resolved tool hand model, action animation and sound override.

In-game validation completed:

```text
crowbar pickup animation/tool presentation: OK
hammer replacement equips the correct tool before striking: OK
wood/metal hammer sound no longer doubles after LMION_HammerPlace: OK
parcel HP tooltip: OK
```

## Parcel durability tooltip — validated in game

`client/LMION/Hooks/Moveables/ParcelTooltip.lua` adds one line to the normal inventory tooltip when a parcel carries transported door health:

```text
FR: Pv : current/max
EN: HP : current/max
```

The display reads `DoorTransportState`; it does not introduce or maintain a second durability value.

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

Player-facing Sandbox help intentionally stays concise. Technical rationale for observed vanilla widths belongs in technical documentation, not the Sandbox tooltip.

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

## Current validation stance

The core gameplay has been exercised repeatedly through the V3 development/refactor cycle and is treated as working unless a new change touches it directly. Do not reopen the full historical regression matrix by default.

At the current head, the recent presentation work has been tested in game for sound and parcel-HP display.
