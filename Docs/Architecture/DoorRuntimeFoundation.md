# Door runtime foundation

This layer sits between LMION definitions and the narrow Project Zomboid integration hooks. Shared door rules stay outside Pickup/Build-specific wrappers.

## Canonical world representation

Every LMION-managed final opening is an `IsoDoor`.

`PZ/DoorObject.lua` reads one source door representation (`IsoDoor` or external/vanilla `IsoThumpable(isDoor)`) and preserves a meaningful `getNorth() == false` value.

`Runtime/CanonicalDoor.lua` converges an LMION-owned source to `IsoDoor`. Build may supply `preserveLockState = false`; pickup/reinstallation preserves transported state by default.

## Durability/state

`Runtime/DoorDurability.lua` owns logical health/max-health access and the `lmionDoorMaxHealth` compatibility key.

`Runtime/DoorState.lua` captures/restores normalized door state.

`Runtime/Moveables/DoorTransportState.lua` serializes only the durability state currently transported through one Moveables item:

```text
lmionDoorHealth
lmionDoorMaxHealth
lmionDoorMaxWasLogical
```

Transport-package appearance is deliberately deferred until Garage and LargeGate runtime behavior exists.

## Frame adapters

`PZ/DoorFrame.lua` has one engine-facing responsibility: classify/query a frame on one square/orientation.

Internal classes:

```text
standard
paired-left   -> DoubleDoor1
paired-right  -> DoubleDoor2
```

`PZ/StandardDoorFrame.lua` asks only for `standard`.

`PZ/PairedDoorFrame.lua` maps semantic Paired members to the corresponding structural frame class:

```text
left  -> paired-left
right -> paired-right
```

The public definition schema does not expose those frame implementation details.

## Placement rules

`Runtime/DoorPlacement.lua` owns world-space validity shared by current 1x1 families:

```text
square exists
-> facing N/W
-> no vehicle intersection
-> no door already occupies that orientation
```

Family-specific final condition:

```text
Simple    -> matching standard frame
Paired    -> matching paired frame member
FenceGate -> no frame
Sliding   -> no frame
```

It exposes separate rule functions and stable failure reasons. It does not check inventory skills/tools.

`Services/Moveables/SingleTileDoorPlacement.lua` selects the appropriate rule from one internal runtime profile. It does not scan the world itself.

## Single-tile Moveables profiles

Current common profile fields are derived from effective definitions rather than hard-coded in hooks.

`Services/Moveables/SingleTileProfileFields.lua` owns reusable field conversion:

- one governing skill level;
- one Moveables tool name;
- transport item type from GameEntity identity;
- package weight;
- script-item existence.

It maps MetalWelding transport tools to LMION-specific Moveables tool definitions so metal objects do not accidentally inherit a Woodwork tool perk.

`Services/Moveables/SingleEntityDoorProfiles.lua` owns the shared single-entity geometry shape used by:

```text
Simple
FenceGate
Sliding
```

A definition becomes runtime-active through this provider only when its corresponding transport script item exists.

`Services/Moveables/PairedDoorProfiles.lua` owns Paired-specific multi-entity/left-right geometry. The first Paired pilot is explicitly limited to `Doors.Wood.BlueChurchDoubleDoor`.

`Services/Moveables/SingleTileDoorProfiles.lua` resolves one supported 1x1 profile by sprite across those specialized providers.

`Services/Moveables/SingleTileDoorMoveProps.lua` applies one resolved profile to vanilla `ISMoveableSpriteProps` and resolves its N/W face.

## Moveables engine lifecycle

`Runtime/Moveables/SingleTileDoorSprites.lua` marks only currently active profile sprites with `IsMoveAble` at `OnLoadedTileDefinitions`.

`Runtime/Moveables/ToolDefinitions.lua` registers the LMION MetalWelding Moveables tool definitions recovered from Legacy:

```text
LMIONMetalScrewdriver
LMIONMetalCrowbar
LMIONMetalHammer
```

`Hooks/Moveables/SingleTileDoor.lua` is the **single owner** of the shared `ISMoveableSpriteProps` wrappers:

```text
new
hasFaces / getFaces
pickUpMoveableInternal
instanceItem
canPlaceMoveableInternal
placeMoveableInternal
```

Unknown/non-LMION objects always return to the previous vanilla implementation. The hook delegates profile derivation, placement rules, durability transport and finalization.

`Services/Moveables/SingleTileDoorPlacementFinalizer.lua` finds the placed object when necessary, canonicalizes it to `IsoDoor`, restores transported durability and logs one stable success/failure boundary.

`Bootstrap/Moveables.lua` installs the tool definitions and the single hook owner, then registers the tile-definition sprite configuration callback.

## Single-tile Build lifecycle

`Services/Build/SingleTileDoorBuildProfile.lua` resolves the currently supported Build pilot from one GameEntity through `EntityIndex`.

Current Build pilots:

```text
Doors.Wood.WhitePanelDoor
Doors.Wood.BlueChurchDoubleDoor
FenceGates.Wood.SmallWhiteWoodenGate
SlidingDoors.BrownSlidingGlassDoor
```

`server/LMION/Hooks/Build/SingleTileDoor.lua` is the **single owner** of the intercepted Build boundaries:

```text
ISBuildIsoEntity.isValid
ISBuildIsoEntity.isValidPerSquare
ISBuildIsoEntity.setInfo
```

Vanilla still owns menu/cursor/timed action/material/tool execution and initial object creation. LMION adds its family placement contract and final canonicalization.

`Services/Build/SingleTileDoorFinalizer.lua` finds the exact built GameEntity, converges it to `IsoDoor`, computes definition-owned construction durability and clears fresh lock state.

## Engine scripts

One file per pilot opening/family contains the strict PZ script-time bridge:

```text
WhitePanelDoor.txt
BlueChurchDoubleDoor.txt
SmallWhiteWoodenGate.txt
BrownSlidingGlassDoor.txt
```

A file may contain several item/entity declarations when the opening itself has several independent members (Paired). This avoids Legacy's separate `_Item`, `_Build` and entity files while keeping parse-time engine declarations together.

Definition data remains authoritative for semantic type, durability, geometry, construction/pickup/replacement facts. Script-time values are duplicated only where PZ requires them before Lua (CraftRecipe, SpriteConfig, XUI and transport item declaration).

## Validation status

**VALIDÉ EN JEU**:

```text
White Panel Simple
Build -> canonical IsoDoor -> Pickup -> replacement
standard frame enforced
HP/max HP preserved
```

**HYPOTHÈSE / NON VALIDÉ** after the current single-tile expansion:

```text
White Panel regression through the renamed shared hook owner
Blue Church Paired left/right frame behavior
Small White Wooden FenceGate no-frame behavior
Brown Sliding Glass Door no-frame + MetalWelding Moveables tools
```

The current expansion changes hook topology and adds `media/scripts`, so the next meaningful checkpoint requires one cold restart rather than Lua reload.
