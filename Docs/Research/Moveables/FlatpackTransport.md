# Transport items / flatpack

Status: **LargeGate segment identity validated enough to restore placement; floor-parcel consumption re-test pending after returning pickup to vanilla lifecycle.**

## Rule

Transport identity and transport appearance are separate concerns.

A transport item must keep the engine information required by vanilla Moveables:

```text
script item identity + WorldSprite + LMION logical state
!=
Icon = Flatpack
```

Do not replace opening-specific transport identity with one universal package item.

## Legacy LargeGate contract

Legacy uses one technical `base:moveable` item per physical leaf segment:

```text
LMION_<Gate>A_Part1
LMION_<Gate>A_Part2
LMION_<Gate>B_Part1
LMION_<Gate>B_Part2
```

Each leaf pickup therefore produces two physical parcels. Replacement can resolve those parcels from inventory or nearby ground.

V3 keeps this physical model without restoring the old separate-mod architecture. The four item declarations live in the normal script file of the corresponding gate family.

## V3 convention

For a semantic entity such as:

```text
Base.LargeFarmGate
```

V3 derives internally:

```text
Base.LMION_LargeFarmGateA_Part1
Base.LMION_LargeFarmGateA_Part2
Base.LMION_LargeFarmGateB_Part1
Base.LMION_LargeFarmGateB_Part2
```

These technical names are not public definition fields. A/B and part index are already consequences of LargeGate geometry.

Each segment item is declared as a Moveable and uses `Icon = Flatpack` only for presentation.

## WorldSprite correction

The first V3 integrated LargeGate test on `5841a976...` produced parcels but neither toolbar nor inventory/right-click placement worked.

Cause: generic `Base.LMION_OpeningParcel` items had LMION identity only in modData and no Moveable WorldSprite.

Vanilla reconstructs Moveables from `item:getWorldSprite()`, so that package could not enter the normal placement path.

**FAILED APPROACH / DO NOT REINTRODUCE:** one generic LargeGate package with no segment WorldSprite.

LargeGate transport now uses the corresponding **closed segment sprite** as the canonical WorldSprite, even when the source gate was open. Partner-state logic decides whether the reconstructed leaf is open or closed; inventory identity stays canonical/stable.

## 2026-09-11 validation after segment-item correction

On commit `b92705e...`, with Project Zomboid 42.20.4:

```text
part 1 left on nearby floor
part 2 moved to inventory
toolbar Place -> functional leaf created
inventory right-click Place -> same functional result
```

This validates:

```text
segment-specific Moveable identity
WorldSprite bootstrap
mixed inventory/floor lookup
both placement frontends
```

It did **not** validate the complete transaction because the floor parcel remained after placement.

## Pickup lifecycle correction

The floor-consumption investigation exposed a more important Legacy/Workshop difference.

Known-good Legacy creates each LargeGate parcel by calling vanilla `pickUpMoveableInternal()` with `isMultiSprite = true`. Vanilla owns creation of the Moveable, `ReadFromWorldSprite`, world-item delivery and source removal.

Workshop replaced this with a manual multisquare helper. The first V3 implementation also manually created/delivered parcels through `LargeGateParcelFactory` and `MoveableDoorSegmentPickup`.

V3 now returns to the Legacy boundary:

```text
resolve physical member
-> ISMoveableSpriteProps.new(closed segment sprite)
-> isMultiSprite = true
-> vanilla pickUpMoveableInternal(...)
-> existing LMION hook owner writes identity + durability onto vanilla-created item
```

This preserves the public/addon-facing model while avoiding a second implementation of the PZ Moveable lifecycle.

## Floor consumption

Vanilla and Legacy both remove a floor parcel with:

```text
transmitRemoveItemFromSquare(worldItem)
removeWorldObject(worldItem)
item:setWorldItem(nil)
```

V3 keeps this sequence. After the 2026-09-11 false-success result, it additionally verifies that the world object actually disappeared before reporting success.

Do not replace these engine calls speculatively unless an exact current-game source/JAR proves the contract changed.

## Simple / Paired

The validated 1x1 path continues to use opening-specific technical items, for example:

```text
Base.LMION_WhitePanelDoor
Base.LMION_BlueChurchDoubleDoorLeft
Base.LMION_BlueChurchDoubleDoorRight
```

LargeGate follows the same principle: engine-visible transport identity belongs to the opening/member, not to a universal LMION package.

## Next validation

Use freshly picked-up parcels after the vanilla-lifecycle correction:

```text
pickup one leaf -> 2 floor parcels
move one parcel to inventory
leave one parcel on the floor
place with toolbar -> both must be consumed
repeat with right-click Place
```

Only after this passes should the LargeGate transport transaction be marked validated.
