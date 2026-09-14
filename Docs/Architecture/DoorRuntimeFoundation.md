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

## Neutral shared services

`Services/Common` contains only knowledge that multiple gameplay subsystems genuinely share.

Current shared boundaries include:

```text
GarageDefinitionProfiles.lua
LargeGateDefinitionProfiles.lua
LargeGateMembers.lua
SingleTileDoorPlacement.lua
```

Build and Moveables consume these neutral services independently. Build does not depend on Moveables profiles merely to identify a Garage or LargeGate, and Runtime does not depend on pickup/transport services merely to understand LargeGate members.

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

Single-tile Build and Moveables use the same neutral rule through `Services/Common/SingleTileDoorPlacement.lua`.

LargeGate and Garage are multi-square and therefore apply compatible edge validation across every physical square of the planned opening.

PZ stores barriers as N/W edges owned by specific squares. Perpendicular structures meeting at a corner are therefore not perfectly symmetric from opposite approach directions. LMION accepts that engine-native edge model and does not add an artificial corner-contact prohibition.

## Single-tile Moveables profiles

Current Moveables profile fields are derived from effective definitions rather than hard-coded in hooks.

`Services/Moveables/MoveableProfileFields.lua` owns reusable Moveables-only conversion such as governing skill, Moveables tool, transport item type and package weight.

`Services/Moveables/SingleTileDoor/SingleEntityProfiles.lua` owns the single-entity profiles used by:

```text
Simple
FenceGate
Sliding
```

`Services/Moveables/SingleTileDoor/PairedProfiles.lua` owns Paired-specific multi-entity/left-right profiles.

`Services/Moveables/SingleTileDoor/Profiles.lua` resolves supported 1x1 profiles by sprite.

`Services/Moveables/SingleTileDoor/MoveProps.lua` applies the resolved profile to vanilla `ISMoveableSpriteProps` and resolves N/W faces.

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

LargeGate and Garage keep family-specific transport/planning/finalization services under:

```text
Services/Moveables/LargeGate/
Services/Moveables/Garage/
```

The shared hook owns the vanilla boundary; family services own family behavior.

## Single-tile Build lifecycle

`Services/Build/SingleTileDoor/Profile.lua` resolves supported Build definitions from GameEntity identity.

`server/LMION/Hooks/Build/SingleTileDoor.lua` owns the single-tile placement validation wrappers:

```text
ISBuildIsoEntity.isValid
ISBuildIsoEntity.isValidPerSquare
```

The hook delegates semantic placement logic to `Services/Common/SingleTileDoorPlacement.lua` and `Runtime/DoorPlacement.lua`.

`server/LMION/Hooks/Build/DoorFrameRequirement.lua` separately owns the definition-to-vanilla frame boolean translation at `ISBuildIsoEntity.new`:

```text
effective definition
-> doorType
-> internal frame requirement
-> buildObject.dontNeedFrame
```

This keeps public definitions semantic while satisfying vanilla Build behavior.

`server/LMION/Hooks/Build/DoorSetInfo.lua` is the centralized post-build `ISBuildIsoEntity.setInfo` owner and dispatches finalization to the appropriate family service.

Vanilla still owns menu/cursor/timed action/base material/tool execution and initial object creation.

## LargeGate Build lifecycle

LargeGate Build-specific services are grouped under `Services/Build/LargeGate/`.

`Profile.lua` resolves the build leaf profile. `BuiltPart.lua` performs the post-build world lookup needed by the LargeGate finalizer, and `Finalizer.lua` canonicalizes/configures the resulting member.

The Build-specific `BuiltPart` lookup intentionally does not live under `PZ`: low-level PZ adapters must not depend on a higher-level gameplay workflow.

## Garage Build lifecycle

Garage Build services are grouped under `Services/Build/Garage/` and split by responsibility rather than accumulated in one large module.

Current responsibilities include:

```text
GarageBuild.lua             build/profile context and length normalization
GarageLengthState.lua       selected length + variable input synchronization
GarageBuildRequirements.lua resource requirements/stock/consumption
GarageBuildFaceProxy.lua    dynamic SpriteConfig face adaptation
GarageBuildFinalizer.lua    pre/post setInfo Garage finalization
```

The client UI widget and its vanilla UI integration are also separate:

```text
client/LMION/UI/Build/GarageLengthSelector.lua
client/LMION/Hooks/Build/GarageBuildUI.lua
```

## Dedicated Moveables cursors

Garage and multipart cursor implementations remain in their original server realm, but they are no longer classified as hooks:

```text
server/LMION/Moveables/GarageCursor.lua
server/LMION/Moveables/LargeGateCursor.lua
```

Their realm was deliberately not changed during the organization pass.

## LargeGate toggle lifecycle

LargeGate A/B leaves are independent runtime units.

PZ recreates internal double-door members during `ToggleDoor()`, so `Runtime/LargeGateToggleState.lua` captures/restores one leaf at a time around that transition.

Neutral member lookup comes from `Services/Common/LargeGateMembers.lua`, not from Moveables transport services.

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
pickup/replacement HP preservation on tested families
canonical final IsoDoor representation
```

The project still distinguishes targeted validated scenarios from an exhaustive all-family/all-resource matrix. Full strict public-schema validation remains deferred until the API shape is complete.
