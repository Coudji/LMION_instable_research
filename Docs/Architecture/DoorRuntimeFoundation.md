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

## `Runtime/DoorDurability.lua`

Responsibility: read/write logical door durability.

It owns the `lmionDoorMaxHealth` compatibility key used when canonical `IsoDoor` cannot express LMION's logical maximum natively.

It does not decide construction durability and does not serialize inventory items.

## `Runtime/DoorState.lua`

Responsibility: capture and restore a normalized door-state snapshot.

It delegates engine classification/orientation to `PZ/DoorObject` and durability to `Runtime/DoorDurability`.

It preserves boolean lock state explicitly; `false` is a real value and must not be converted to `nil`.

## `Diagnostics/DefinitionIndex.lua`

Responsibility: exercise the pure entity reverse index during DEV bootstrap.

It forces resolution/indexing of the registered catalog and verifies the stable pilot mapping:

```text
Base.WhitePanelDoor -> Doors.Wood.WhitePanelDoor
```

This gives an early diagnostic before gameplay hooks exist. The count is logged rather than hard-coded so third-party registrations remain possible.

## Still intentionally absent

This foundation does not yet implement:

- frame scanning/placement validation;
- world-object canonicalization to `IsoDoor`;
- Moveables hooks;
- Pickup parcel/item serialization;
- placement finalization;
- Build finalization;
- Garage/LargeGate runtime.

Those responsibilities are added only when their concrete use case is introduced.
