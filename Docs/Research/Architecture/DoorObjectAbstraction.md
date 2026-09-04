# Door object abstraction — V3 active note

Status: architectural contract adopted from Legacy research; runtime integration in V3 not yet validated.

## Canonical representation

Project Zomboid may expose a semantic door as either `IsoDoor` or `IsoThumpable(isDoor)`.

LMION V3 accepts both as source/input representations, but every door created, finalized or reinstalled by LMION must end as `IsoDoor`.

There is no world-wide migration scan. Canonicalization happens only at explicit LMION ownership boundaries such as Build finalization or Pickup reinstallation.

## Orientation

B42 uses `getNorth()` as a meaningful boolean:

```text
true  -> N
false -> W
```

A valid `false` must never be collapsed to `nil` through Lua's `a and b or fallback` idiom. Read the boolean explicitly, then branch on `nil` versus `false`.

This was a real Legacy runtime failure mode for W-facing temporary construction objects.

## Durability

Source `IsoThumpable` objects may expose native `setMaxHealth()`. Canonical `IsoDoor` does not expose an equivalent useful setter, so LMION stores an effective logical maximum in:

```text
modData.lmionDoorMaxHealth
```

Current health still uses the engine door health field.

Pickup transports actual source durability; it does not decide a new durability value. Build owns fresh-construction durability.

## Normalized state

The reusable state boundary captures/restores gameplay state independently from Java representation:

- current health;
- effective max health;
- whether the max was a logical override;
- key ID;
- locked state;
- locked-by-key state;
- modData.

Source representation may be retained for diagnostics only; it must not select the final physical backend.

## V3 implementation boundary

The first V3 runtime foundation deliberately separates:

- `PZ/DoorObject.lua` — recognize/read the engine object and orientation;
- `Runtime/DoorDurability.lua` — current/effective durability only;
- `Runtime/DoorState.lua` — normalized state snapshot/restore only.

No hook, world mutation or canonicalization is installed by these files yet.

Source: Legacy `Research/Architecture/DoorObjectAbstraction.md` and the validated Legacy `Doors/Object.lua`, `Doors/Durability.lua`, `Doors/State.lua`, `Doors/Representation.lua` behavior.
