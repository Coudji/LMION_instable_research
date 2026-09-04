# Door runtime foundation

This is the first runtime-facing layer after the data catalog and GameEntity lookup foundation. Shared door rules stay outside Pickup/Build-specific integration.

## `PZ/DoorObject.lua`

Responsibility: read the engine representation of one door object.

It can recognize `IsoDoor`, recognize `IsoThumpable(isDoor)`, report the source representation, read `getNorth()` without losing a valid `false`, and expose `N` / `W` facing.

It does not capture state, change health, mutate the world or resolve LMION definitions.

## `PZ/DoorSprite.lua`

Responsibility: derive N/W facing from one door sprite's engine flags.

It does not resolve definitions or mutate sprites.

## `PZ/StandardDoorFrame.lua`

Responsibility: answer one question only: does the target square contain a standard frame for the requested N/W orientation?

It accepts both construction-style `IsoThumpable` door frames and static/map frame objects. It rejects paired-frame classes carrying `DoubleDoor1` / `DoubleDoor2` flags.

It does not decide whether a complete placement is valid and does not inspect LMION definitions.

## `PZ/PlacedDoor.lua`

Responsibility: find the just-placed door on one square by exact sprite name.

It exists only as a fallback when vanilla `placeMoveableInternal()` does not directly return the placed door object.

## `Runtime/DoorDurability.lua`

Responsibility: read/write logical door durability.

It owns the `lmionDoorMaxHealth` compatibility key used when canonical `IsoDoor` cannot express LMION's logical maximum natively.

It does not decide construction durability and does not serialize inventory items.

## `Runtime/DoorState.lua`

Responsibility: capture and restore a normalized door-state snapshot.

It delegates engine classification/orientation to `PZ/DoorObject` and durability to `Runtime/DoorDurability`.

It preserves boolean lock state explicitly; `false` is a real value and must not be converted to `nil`.

## `Runtime/DoorPlacement.lua`

Responsibility: decide whether one Simple 1x1 door can occupy one target square/facing.

Current decision order:

```text
square exists
-> facing is N or W
-> no vehicle intersection
-> no door already occupies that orientation
-> matching standard frame exists
```

It returns both a boolean and a stable diagnostic reason such as `missing-standard-frame` or `door-already-present`.

It does not check inventory tools/skills; the Moveables integration preserves vanilla checks for those requirements.

## `Runtime/CanonicalDoor.lua`

Responsibility: converge one LMION-owned source door to canonical `IsoDoor` representation.

An existing `IsoDoor` is returned unchanged. A source `IsoThumpable(isDoor)` has its state captured, is recreated as `IsoDoor` on the same square/sprite/orientation, has its state restored, requests GameEntity reconstruction when relevant, and only then replaces the temporary source object.

Fresh Build callers can later pass `preserveLockState = false`; Pickup/reinstallation preserves transported state by default.

## `Runtime/Moveables/DoorTransportState.lua`

Responsibility: serialize only the durability state currently transported through a Moveables item:

```text
lmionDoorHealth
lmionDoorMaxHealth
lmionDoorMaxWasLogical
```

It does not know about vanilla hooks or placement.

## `Services/Moveables/SimpleDoorProfiles.lua`

Responsibility: derive the Moveables-facing profile for a Simple definition whose transport item exists.

The first runtime slice intentionally creates only `Base.LMION_WhitePanelDoor`, so only that definition becomes active through this service. The service already derives identity and exact N/W faces from effective definition data rather than duplicating sprite numbers in the hook.

Definitions without a corresponding transport item or unsupported tool shape are skipped instead of receiving a broken partial profile.

## `Runtime/Moveables/SimpleDoorSprites.lua`

Responsibility: mark the sprites of active Simple profiles with `IsMoveAble` at `OnLoadedTileDefinitions`.

It owns no vanilla method wrapper.

## `Services/Moveables/SimpleDoorPlacementFinalizer.lua`

Responsibility: finalize the result of one Simple Moveables placement.

It finds the placed door when necessary, canonicalizes it to `IsoDoor`, restores transported durability, and emits one final success/failure diagnostic.

## `Hooks/Moveables/SimpleDoor.lua`

Responsibility: own the first narrow `ISMoveableSpriteProps` wrappers.

It calls vanilla first wherever vanilla remains authoritative and delegates LMION work to the modules above. It owns the control points documented in `Docs/Research/Moveables/SimpleMoveablesHook.md`:

```text
new
hasFaces / getFaces
pickUpMoveableInternal
instanceItem
canPlaceMoveableInternal
placeMoveableInternal
```

The `canPlaceMoveableInternal` hook intentionally replaces only the spatial-validity branch for matched LMION Simple doors, then preserves vanilla skill/tool checks. Unknown/non-LMION moveables always return to the previous implementation.

No per-frame logs are emitted from placement validation.

## `Bootstrap/Moveables.lua`

Responsibility: install the Simple hook once and register the sprite-configuration lifecycle callback.

It contains no pickup/placement business rule.

## `Diagnostics/DefinitionIndex.lua`

Responsibility: exercise the pure entity reverse index during DEV bootstrap.

It verifies:

```text
Base.WhitePanelDoor -> Doors.Wood.WhitePanelDoor
```

## First runtime checkpoint

The first functional pilot is intentionally one door:

```text
Doors.Wood.WhitePanelDoor
Base.WhitePanelDoor
Base.LMION_WhitePanelDoor
```

This checkpoint is expected to exercise:

```text
world IsoDoor
-> vanilla Moveables pickup
-> one inventory Moveable item
-> transported HP/max HP
-> vanilla rotation/cursor behavior
-> LMION standard-frame placement check
-> vanilla placement
-> LMION canonical IsoDoor finalization
-> restored HP/max HP
```

Because this slice adds a new `media/scripts` item definition and a new hook installation path, its first validation requires a cold PZ restart.

## Still intentionally absent

This first hook does not yet activate every Simple definition, Paired, FenceGate, Sliding, Garage, LargeGate, Build finalization, custom pickup animations, or final release logging policy.

Those are extended only after the one-door Simple loop is runtime-validated.
