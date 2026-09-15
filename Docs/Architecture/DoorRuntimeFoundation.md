# Door runtime foundation

This layer sits between LMION definitions and narrow Project Zomboid integration hooks. Shared rules live outside Build/Moveables-specific wrappers.

## Canonical world representation

Every LMION-managed final opening is an `IsoDoor`.

`PZ/DoorObject.lua` recognizes source `IsoDoor` and compatible external/vanilla `IsoThumpable(isDoor)` representations. `Runtime/CanonicalDoor.lua` converges LMION-owned results to the canonical `IsoDoor` representation.

`Runtime/DoorDurability.lua` owns logical health/max-health access. `Runtime/DoorState.lua` owns normalized capture/restore semantics. Moveables transport state remains separate from normal world-toggle state.

## Neutral shared services

Current shared family structure:

```text
Services/Common/Garage/Profiles.lua
Services/Common/LargeGate/Profiles.lua
Services/Common/LargeGate/Members.lua
Services/Common/LargeGate/PlacementSpace.lua
Services/Common/SingleTileDoor/Placement.lua
```

Build and Moveables consume these independently. Build does not import Moveables profiles to identify or validate an opening.

## Frame and edge placement

`Runtime/DoorPlacement.lua` owns shared N/W edge validity.

Internal support consequence:

```text
Simple    -> matching standard frame required
Paired    -> matching paired frame member required
FenceGate -> no frame; edge must be free
Sliding   -> no frame; edge must be free
LargeGate -> no frame; closed edges must be free
Garage    -> no frame; planned edges must be free
```

`none` means no supporting frame is required; it never means that an existing wall, fence, frame, window, door or Garage edge may be overwritten.

`Services/Common/SingleTileDoor/Placement.lua` dispatches the correct rule for the four 1x1 semantic families.

## LargeGate operational placement

LargeGate placement deliberately does **not** infer a partner leaf.

Each A/B leaf is validated independently from `LargeGateTopology` and is placed closed. PZ receives the correct native sprites/logical indices and owns normal double-door grouping afterwards.

`Services/Common/LargeGate/PlacementSpace.lua` derives the full native 2x2 swing square from the leaf's closed/open offsets. Validation rejects:

```text
solid / solid-trans / tree / vehicle obstruction in the swing square
walls, windows, doors or other barriers cutting through the swing path
swing overlap with any existing LMION LargeGate leaf
```

This rule is shared by:

```text
server/LMION/Hooks/Build/LargeGate.lua
Services/Moveables/LargeGate/PlacementPlan.lua
```

The LargeGate-vs-LargeGate protection is symmetric: a new leaf cannot prevent an existing LargeGate from opening.

The protection is intentionally **not global**. Garage, FenceGate or other constructions placed later are allowed to block an existing LargeGate; that may be player error or intentional defensive construction. See `Docs/Decisions/LargeGatePlacementSpace.md`.

Invalid LargeGate inventory placements remain renderable as a red ghost rather than disappearing.

## Moveables engine lifecycle

`Hooks/Moveables/SpriteProps.lua` owns the shared `ISMoveableSpriteProps` wrappers used across LMION door families:

```text
new
hasFaces / getFaces
pickUpMoveableInternal
instanceItem
canPlaceMoveableInternal
placeMoveableInternal
```

Unknown/non-LMION objects delegate to the previous vanilla implementation.

Family-specific transport/planning/finalization remains under:

```text
Services/Moveables/SingleTileDoor/
Services/Moveables/LargeGate/
Services/Moveables/Garage/
```

The old LargeGate partner-state `WorldState.lua` service is gone because partner inference is no longer part of placement.

## Inventory placement versus toolbar placement

Inventory/right-click placement has its own routing boundary:

```text
client/LMION/Hooks/Moveables/InventoryPlacement.lua
```

Current behavior:

```text
single-tile door parcel -> DoorInventoryCursor
LargeGate parcel        -> DoorInventoryCursor
Garage parcel           -> GarageCursor (variable width)
unknown Moveable        -> vanilla
```

`DoorInventoryCursor` preserves inventory placement semantics, including `R` rotation, without activating the Moveables toolbar.

Garage inventory placement keeps its validated variable-width `+/-` behavior. Vanilla toolbar Garage placement intentionally remains the fixed L3 path.

`server/LMION/Hooks/Moveables/MultipartGhost.lua` owns only the multipart `ISMoveableCursor` ghost-rendering boundary for Garage pickup and LargeGate SpriteGrid previews. It is not a cursor implementation.

## Build lifecycle

Single-tile Build profile/finalization lives under `Services/Build/SingleTileDoor/`.

LargeGate Build profile, built-member lookup and finalization live under `Services/Build/LargeGate/`. Supported vanilla leaf-A GameEntities are narrowed at the validated runtime lifecycle boundary by `Runtime/Build/VanillaLargeGateLeafPreparation.lua`; LMION does not statically redeclare those vanilla entities.

Garage Build services are:

```text
Services/Build/Garage/Build.lua
Services/Build/Garage/LengthState.lua
Services/Build/Garage/Requirements.lua
Services/Build/Garage/FaceProxy.lua
Services/Build/Garage/Finalizer.lua
```

The family directory already supplies context, so redundant `GarageBuild*` filename prefixes were removed.

Client Garage Build UI is split between:

```text
client/LMION/UI/Build/GarageLengthSelector.lua
client/LMION/Hooks/Build/Garage.lua
```

## LargeGate toggle lifecycle

LargeGate A/B leaves are independent runtime units. PZ recreates internal double-door members during `ToggleDoor()`, so `Runtime/LargeGateToggleState.lua` captures/restores one leaf around that transition using `Services/Common/LargeGate/Members.lua` and `LargeGateTopology`.

This implementation exists, but HP preservation across normal open/close must not be described as runtime-validated until the dedicated in-game toggle test is completed.

## Static script ownership

LMION static scripts may declare LMION transport items and custom LMION entities required by the engine.

They must not redeclare an existing vanilla GameEntity. The startup failure caused by duplicate vanilla `SpriteConfig` tiles established this as an explicit rule.

For the three vanilla LargeGate bases (`DoubleDoor`, `DoubleFenceGate`, `DoubleWireGate`), static LMION files retain the LMION parcel items and custom B entity only; vanilla A remains owned by PZ and is adapted at runtime.

## Current validation status

Recent in-game stabilization confirmed:

```text
startup with 23 defaults / 72 definitions
Simple / Paired / FenceGate representative 1x1 behavior
inventory placement separated from toolbar with R rotation
LargeGate inventory replacement and visible invalid ghosts
LargeGate full 2x2 swing-space obstruction rules
LargeGate-vs-LargeGate swing conflict prevention
Garage inventory variable-width path remains functional
```

The project still distinguishes representative validation from an exhaustive all-definition/all-resource matrix. LargeGate normal ToggleDoor HP preservation remains specifically pending.
