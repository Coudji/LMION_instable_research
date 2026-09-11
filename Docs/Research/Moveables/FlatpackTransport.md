# Transport items / flatpack

Status: **LargeGate segment identity, mixed inventory/floor lookup and floor-parcel consumption are validated in game.**

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

Each leaf pickup therefore produces two physical parcels. Replacement resolves each required part independently from inventory first, then nearby ground. Parcels from different pickup sessions remain interchangeable as long as the required part identity matches; durability belongs to the selected parcel.

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

## 2026-09-11 placement validation after segment-item correction

On commit `b92705e...`, with Project Zomboid 42.20.4:

```text
part 1 left on nearby floor
part 2 moved to inventory
toolbar Place -> functional leaf created
inventory right-click Place -> same functional result
```

This validated:

```text
segment-specific Moveable identity
WorldSprite bootstrap
mixed inventory/floor lookup
both placement frontends
```

The complete transaction was not yet valid at that point because the part-1 floor parcel remained after placement.

## Pickup lifecycle correction

The floor-consumption investigation exposed an important Legacy/Workshop difference.

Known-good Legacy creates each LargeGate parcel by calling vanilla `pickUpMoveableInternal()` with `isMultiSprite = true`. Vanilla owns creation of the Moveable, `ReadFromWorldSprite`, world-item delivery and source removal.

Workshop replaced this with a manual multisquare helper. The first V3 implementation also manually created/delivered parcels through `LargeGateParcelFactory` and `MoveableDoorSegmentPickup`.

V3 now follows the Legacy boundary:

```text
resolve physical member
-> ISMoveableSpriteProps.new(closed segment sprite)
-> isMultiSprite = true
-> vanilla pickUpMoveableInternal(...)
-> existing LMION hook owner writes identity + durability onto vanilla-created item
```

This preserves the public/addon-facing model while avoiding a second implementation of the PZ Moveable lifecycle.

**FAILED REFACTOR PATTERN / DO NOT REINTRODUCE BY DEFAULT:** manually recreating vanilla multipart pickup when Legacy proves the vanilla lifecycle works.

## Floor consumption — validated correction

Vanilla and Legacy remove a floor parcel with the normal world-item removal sequence:

```text
transmitRemoveItemFromSquare(worldItem)
removeWorldObject(worldItem)
item:setWorldItem(nil)
```

The V3 defect was in **which world object was being consumed**, not in those engine calls themselves. Lookup selected the correct floor parcel and placement restored its durability, but consumption later recovered the world object again from the `InventoryItem` after placement.

The validated correction is:

```text
floor lookup
-> capture the exact selected IsoWorldInventoryObject
-> retain that reference in the placement plan
-> place/finalize both members
-> consume the exact retained world object
```

The placement plan no longer gives the cursor-launching item any `preferred` privilege. Part1 and Part2 are looked up independently, matching the Legacy stock model.

Commits involved in the final correction include:

```text
1d83215c209053830384e7d7bd330b110bc494ec  Align LargeGate placement lookup with Legacy
a37ead498fc1f2ee26d5164e44ca30b5d8113cee  Capture exact LargeGate floor parcel object
4b097bbf9a81a76bc4b9fbf29ff853c06c553179  Retain selected LargeGate floor world object
5cb06b60129ab61d83f19cdf04535d942e5b20cb  Consume exact selected LargeGate floor parcel
613b4ef14e716f71c7ccedc0a4ae4058cc6ca851  Use exact floor parcel during LargeGate placement
```

The previously failing arrangement — **Part2 in inventory + Part1 on the floor** — now consumes both parcels correctly in game. The inverse arrangement had already worked. LargeGate mixed inventory/floor stock consumption is therefore considered validated for this replacement path.

Do not replace the engine removal calls speculatively; preserve the selected world-object identity through the transaction instead.

## Simple / Paired

The validated 1x1 path continues to use opening-specific technical items, for example:

```text
Base.LMION_WhitePanelDoor
Base.LMION_BlueChurchDoubleDoorLeft
Base.LMION_BlueChurchDoubleDoorRight
```

LargeGate follows the same principle: engine-visible transport identity belongs to the opening/member, not to a universal LMION package.
