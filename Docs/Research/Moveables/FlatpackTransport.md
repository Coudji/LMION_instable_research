# Transport items / flatpack

Status: **LargeGate decision implemented on 2026-09-11; in-game re-validation pending.**

## Rule

Transport identity and transport appearance are separate concerns.

A transport item must keep the engine information required by vanilla Moveables. The flatpack is only the inventory presentation:

```text
script item identity + WorldSprite + LMION state
!=
Icon = Flatpack
```

Do not replace opening-specific transport identity with one universal package item.

## Validated reference behavior

Legacy is the gameplay oracle.

For LargeGate, Legacy uses one technical `base:moveable` item per physical leaf segment:

```text
LMION_<Gate>A_Part1
LMION_<Gate>A_Part2
LMION_<Gate>B_Part1
LMION_<Gate>B_Part2
```

Each leaf pickup therefore produces two physical parcels. The two parcels can be found in inventory or on nearby ground and are consumed when that leaf is replaced.

V3 keeps that visible/physical model but does not copy the old Pickup-mod architecture. The four item declarations live in the script file of the corresponding opening family.

## V3 LargeGate convention

For a built-in definition whose semantic entity is for example:

```text
Base.LargeFarmGate
```

V3 derives the segment items:

```text
Base.LMION_LargeFarmGateA_Part1
Base.LMION_LargeFarmGateA_Part2
Base.LMION_LargeFarmGateB_Part1
Base.LMION_LargeFarmGateB_Part2
```

The public Lua definition does not expose those technical item names. Leaf/part identity is already derivable from LargeGate geometry and stays an internal runtime consequence.

Each segment item is declared as:

```text
ItemType = base:moveable
Icon = Flatpack
```

The runtime keeps the authoritative transport weight from the effective LMION definition.

## WorldSprite is required

The first V3 integrated LargeGate placement test was performed from commit:

```text
5841a976ae8d2cf7f1928825fd266f76158c1b00
```

Observed result:

```text
Pickup produced the LargeGate parcels.
Placement failed from inventory right-click.
Placement failed from the vanilla Moveables toolbar.
```

The implementation at that commit created every segment as the generic:

```text
Base.LMION_OpeningParcel
```

and wrote LMION identity/durability into modData, but never called `Moveable:ReadFromWorldSprite(...)`.

That loses information required by vanilla Moveables. In particular, the vanilla inventory placement path reconstructs move props from:

```lua
ISMoveableSpriteProps.new(item:getWorldSprite())
```

So a technical `base:moveable` package without the segment WorldSprite cannot participate correctly in either placement frontend.

**FAILED APPROACH / DO NOT REINTRODUCE:** one generic `LMION_OpeningParcel` with only modData identity and no WorldSprite.

## Canonical transported sprite

LargeGate parcels use the corresponding **closed segment sprite** as their WorldSprite, even if the source gate was open.

Reason:

- V3 runtime SpriteGrids are attached to closed LargeGate sprites;
- closed N/W sprites are the canonical transport faces;
- logical durability remains in item modData;
- open replacement is determined by the existing partner-state/topology logic, not by transporting an open sprite as inventory identity.

The parcel factory therefore follows the vanilla mechanism:

```text
instanceItem(segment item type)
-> Moveable:ReadFromWorldSprite(closed segment sprite)
-> apply LMION weight/name/identity/durability
```

## Simple / Paired

The already validated 1x1 path continues to use its opening-specific script items, for example:

```text
Base.LMION_WhitePanelDoor
Base.LMION_BlueChurchDoubleDoorLeft
Base.LMION_BlueChurchDoubleDoorRight
```

LargeGate now follows the same principle: engine-visible transport items belong to the opening, not to a universal LMION parcel type.

## Validation still required

The 2026-09-11 change is an implementation correction derived from Legacy and vanilla Moveables behavior. It is **not yet marked VALIDATED EN JEU**.

Next LargeGate test must confirm both frontends independently:

```text
inventory right-click -> Place
Moveables toolbar -> Place
```

and then re-check:

```text
N/W rotation
A/B leaf identity
2 parcels per leaf
inventory + nearby-floor lookup
partner open/closed coherence
HP/max-HP persistence
```

Sources: validated Legacy LargeGate parcel scripts/specs and B42 Moveables Lua behavior.
