# Door runtime foundation

This layer sits between LMION definitions and the narrow Project Zomboid integration hooks. Shared door rules stay outside Pickup/Build-specific wrappers.

## Canonical world representation

Every LMION-managed final opening is an `IsoDoor`.

`PZ/DoorObject.lua` reads source door representations (`IsoDoor` or external/vanilla `IsoThumpable(isDoor)`) and preserves meaningful facing data.

`Runtime/CanonicalDoor.lua` converges an LMION-owned source to `IsoDoor`. Build may use a fresh-state path; pickup/replacement restores transported state.

## Durability/state

`Runtime/DoorDurability.lua` owns logical health/max-health access and the `lmionDoorMaxHealth` compatibility key.

`Runtime/DoorState.lua` owns normalized capture/restore semantics.

Moveables transport state remains separate from normal world-toggle state. In particular, LargeGate open/close preservation uses `DoorState` around PZ's internal recreation boundary rather than parcel transport.

## Frame adapters

`PZ/DoorFrame.lua` classifies/query frames on one square/orientation.

Internal classes:

```text
standard
paired-left
paired-right
```

`PZ/StandardDoorFrame.lua` asks only for `standard`.

`PZ/PairedDoorFrame.lua` maps semantic Paired members to the matching structural frame class.

These implementation details are not public definition fields.

## Placement rules

`Runtime/DoorPlacement.lua` owns shared world-space validity for door edges.

Common checks include:

```text
square exists
facing is N or W
no vehicle intersection
no door already occupies the same orientation
```

Family-specific support rules:

```text
Simple    -> matching standard frame required
Paired    -> matching paired frame member required
FenceGate -> no frame required, target edge must be free
Sliding   -> no frame required, target edge must be free
LargeGate -> no frame required, every Build/placement edge must be free
Garage    -> no frame required, every Build/placement edge must be free
```

For unframed openings, `none` means no supporting frame is required. It does not authorize overlapping an already occupied N/W edge.

The current blocking-edge rule rejects incompatible structures such as walls, fences/hoppable walls, standard or paired frames, windows/window frames and existing door/garage-door edges.

FenceGate and Sliding use the rule directly through `Services/Moveables/SingleTileDoorPlacement.lua` and the single-tile Build hook.

LargeGate and Garage are multi-square and therefore apply the same rule through `ISBuildIsoEntity.isValidPerSquare`, validating each physical square of the current Build footprint.

PZ stores barriers as N/W edges owned by specific squares. Perpendicular structures meeting at a corner are therefore not perfectly symmetric from opposite approach directions. LMION accepts that engine-native edge model and does not add an artificial corner-contact prohibition.

## Single-tile Moveables profiles

Current common profile fields are derived from effective definitions rather than hard-coded in hooks.

`Services/Moveables/SingleTileProfileFields.lua` owns reusable field conversion such as governing skill, Moveables tool, transport item type and package weight.

`Services/Moveables/SingleEntityDoorProfiles.lua` owns the shared single-entity geometry used by:

```text
Simple
FenceGate
Sliding
```

`Services/Moveables/PairedDoorProfiles.lua` owns Paired-specific multi-entity/left-right geometry.

`Services/Moveables/SingleTileDoorProfiles.lua` resolves supported 1x1 profiles by sprite.

`Services/Moveables/SingleTileDoorMoveProps.lua` applies the resolved profile to vanilla `ISMoveableSpriteProps` and resolves N/W faces.

## Moveables engine lifecycle

`Hooks/Moveables/SingleTileDoor.lua` is the shared owner of the relevant `ISMoveableSpriteProps` wrappers:

```text
new
hasFaces / getFaces
pickUpMoveableInternal
instanceItem
canPlaceMoveableInternal
placeMoveableInternal
```

Unknown/non-LMION objects fall back to the previous vanilla implementation.

LargeGate and Garage add family-specific planning/finalization services while preserving the same ownership rule: one identifiable vanilla boundary has one identifiable hook owner.

## Single-tile Build lifecycle

`Services/Build/SingleTileDoorBuildProfile.lua` resolves supported Build definitions from GameEntity identity.

`server/LMION/Hooks/Build/SingleTileDoor.lua` owns the single-tile placement validation wrappers:

```text
ISBuildIsoEntity.isValid
ISBuildIsoEntity.isValidPerSquare
```

The hook delegates all semantic placement logic to `SingleTileDoorPlacement` / `DoorPlacement`.

`Hooks/Build/DoorFrameRequirement.lua` separately owns the definition-to-vanilla frame boolean translation at `ISBuildIsoEntity.new`:

```text
effective definition
-> doorType
-> internal frame requirement
-> buildObject.dontNeedFrame
```

This keeps public definitions semantic while satisfying vanilla Build behavior.

`Hooks/Build/DoorSetInfo.lua` is the centralized post-build `ISBuildIsoEntity.setInfo` owner and dispatches finalization to the appropriate family service.

Vanilla still owns menu/cursor/timed action/base material/tool execution and initial object creation.

## LargeGate toggle lifecycle

LargeGate A/B leaves are independent runtime units.

PZ recreates internal double-door members during `ToggleDoor()`, so `Runtime/LargeGateToggleState.lua` captures/restores one leaf at a time around that transition:

```text
leaf A -> 2 members
leaf B -> 2 members
```

The partner leaf may be absent. This is validated in game for HP preservation on A alone, B alone and a complete A+B gate.

`DoorState`, `DoorDurability`, `LargeGateMembers` and `LargeGateTopology` remain the sources of truth for state, durability, identity and geometry respectively. The toggle runtime owns timing only.

## Engine scripts

PZ script files contain only parse-time data the engine still needs before Lua, such as:

```text
transport item declarations
XUI data
CraftRecipe data
SpriteConfig geometry
```

Definition data remains authoritative for semantic type, durability, geometry ownership and gameplay policy where V3 can safely apply it at runtime.

Static scripts must not duplicate derived frame policy merely as documentation.

## Validation status

Validated in game across the current pilots and tested multi-square families:

```text
Simple standard-frame requirement
Paired frame-member behavior
FenceGate no-frame behavior
Sliding no-frame behavior
LargeGate A/B no-frame Build behavior
Garage no-frame Build behavior
occupied-edge rejection for unframed families
LargeGate HP preservation on complete and independent leaves
pickup/replacement HP preservation on tested families
canonical final IsoDoor representation
```

The project still distinguishes targeted validated scenarios from an exhaustive all-family/all-resource matrix. Full strict public-schema validation remains deferred until the API shape is complete.
