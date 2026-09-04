# Door runtime foundation

This is the first runtime-facing layer after the data catalog and GameEntity lookup foundation. It intentionally does not own Pickup or Build.

## `PZ/DoorObject.lua`

Responsibility: read the engine representation of one door object.

It can:

- recognize `IsoDoor`;
- recognize `IsoThumpable(isDoor)`;
- report the source representation;
- read `getNorth()` without losing a valid `false` value;
- expose the corresponding `N` / `W` facing.

It does not capture state, change health, mutate the world or resolve LMION definitions.

## `PZ/StandardDoorFrame.lua`

Responsibility: answer one question only: does the target square contain a standard frame for the requested N/W orientation?

It accepts both construction-style `IsoThumpable` door frames and static/map frame objects. It rejects paired-frame classes carrying `DoubleDoor1` / `DoubleDoor2` flags.

It does not decide whether a complete placement is valid and does not inspect LMION definitions.

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

It returns both a boolean and a stable diagnostic reason such as `missing-standard-frame` or `door-already-present` so later Moveables logs do not need to reverse-engineer why placement was refused.

It does not check inventory tools/skills; vanilla Moveables remains responsible for those gameplay requirements.

## `Runtime/CanonicalDoor.lua`

Responsibility: converge one LMION-owned source door to canonical `IsoDoor` representation.

- an existing `IsoDoor` is returned unchanged;
- a source `IsoThumpable(isDoor)` has its normalized state captured;
- a new `IsoDoor` is created on the same square/sprite/orientation;
- state is restored;
- GameEntity reconstruction is requested when the sprite carries `EntityScript`;
- the temporary source object is removed only after the canonical door is added.

Fresh Build callers can pass `preserveLockState = false`; Pickup/reinstallation will preserve transported lock state by default.

DEV logs are emitted on canonicalization failure/success boundaries. No automatic world scan calls this module.

## `Diagnostics/DefinitionIndex.lua`

Responsibility: exercise the pure entity reverse index during DEV bootstrap.

It forces resolution/indexing of the registered catalog and verifies the stable pilot mapping:

```text
Base.WhitePanelDoor -> Doors.Wood.WhitePanelDoor
```

This gives an early diagnostic before gameplay hooks exist. The count is logged rather than hard-coded so third-party registrations remain possible.

## Still intentionally absent

This foundation does not yet implement:

- Moveables hooks;
- Pickup parcel/item serialization;
- Simple placement finalization after vanilla placement;
- Build finalization hook;
- Garage/LargeGate runtime.

The next integration step is the first narrow Simple Moveables path, using these shared runtime responsibilities rather than putting frame/state/canonicalization rules inside Pickup.
