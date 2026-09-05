# Flatpack transport — V3

Status: **ARCHITECTURE UNDER REVIEW / DO NOT TEST YET**. The generic `Base.LMION_Flatpack` pilot is implemented for White Panel Door but is intentionally paused before runtime validation while transport identity is compared against multisprite families.

## Product rule

A picked-up opening is transported visually as a **flatpack**. This does **not** imply that every transported opening must share one script item type.

Two separate decisions must not be conflated:

```text
visual representation -> flatpack icon/model
transport identity     -> generic item + metadata OR typed flatpack item
```

The first is a product decision. The second is an engine/integration architecture decision.

## Simple baseline — OBSERVÉ DANS LEGACY

Legacy used one `ItemType = base:moveable` script item per Simple door. Example:

```text
Base.LMION_WhitePanelDoor
```

The item script contained only moveable-engine metadata and a per-door weight. The Moveables hook set `moveProps.customItem` to that item type and let vanilla `instanceItem()` create the inventory object.

Door health/max-health were dynamic modData. Source Java representation was deliberately not transported; placement converged to canonical `IsoDoor`.

Therefore, for Simple doors, the item full type can naturally carry definition identity while all such items still share one flatpack visual.

## Vanilla flatpack visual — OBSERVÉ DANS VANILLA / SOURCE

B42.20.3 contains the vanilla model:

```text
model Flatpack
{
    mesh = WorldItems/Flatpack,
    scale = 0.175,
}
```

LMION can therefore reuse the vanilla `Flatpack` world model. Inventory icon choice is independent from transport identity and may also be shared by every LMION flatpack item.

## Multisprite transport — OBSERVÉ DANS LEGACY

### LargeGate

A LargeGate logical leaf contains **two physical members**. Legacy transports one parcel per member and gives every member an exact item type.

Example for Large Wrought Iron Gate:

```text
A/Part1 -> Base.LMION_LargeWroughtIronGateA_Part1
A/Part2 -> Base.LMION_LargeWroughtIronGateA_Part2
B/Part1 -> Base.LMION_LargeWroughtIronGateB_Part1
B/Part2 -> Base.LMION_LargeWroughtIronGateB_Part2
```

The LargeGate Moveables integration uses these exact full types as part identity. In particular, its narrow `findInInventoryMultiSprite()` hook resolves the requested `(1/2)` or `(2/2)` grid member and searches inventory/nearby floor for the exact corresponding item type.

So item identity currently participates directly in the validated multisprite integration contract:

```text
family + leaf A/B + physical part 1/2
-> exact item full type
-> compatible parcel lookup
```

Compatible parcels are interchangeable by this **part identity**; there is no bundle ID tying two parcels to the same pickup operation.

### Garage

Garage transport uses three semantic parcel roles per family:

```text
Part1 = START
Part2 = MIDDLE (repeatable)
Part3 = END
```

Legacy defines exact item types such as:

```text
Base.LMION_GreenGarageDoor_Part1
Base.LMION_GreenGarageDoor_Part2
Base.LMION_GreenGarageDoor_Part3
```

`GarageDoorSpecs` builds a `ParcelsByItemType` reverse index, and vanilla-toolbar multisprite lookup searches the character inventory for the exact full type required by the requested SpriteGrid member.

The type therefore naturally encodes:

```text
garage family + START/MIDDLE/END role
```

This is especially useful because MIDDLE is repeatable and parcels are intentionally interchangeable by role rather than pickup bundle.

### Paired

Paired doors are not a single vanilla multisprite object in the same sense as Garage/LargeGate. They are independent 1x1 leaves. Their transport identity can remain leaf-specific without needing a generic multipart bundle concept.

## Consequence for the generic-item idea

A single `Base.LMION_Flatpack` can technically carry all identity in modData:

```text
definitionId
leaf
part/member role
```

but doing so for multisprite families would force LMION to replace more of the existing exact-item-type matching at vanilla Moveables boundaries. The current Legacy behavior can often ask simply:

```lua
item:getFullType() == requiredPart.itemType
```

With one generic type, every such lookup must instead inspect and validate modData identity. That is possible, but it adds integration plumbing precisely at the multisprite paths that were hardest to stabilize historically, especially toolbar placement.

**Current evidence therefore favors typed flatpacks over one universal flatpack item.**

That would mean:

```text
Simple
    one typed flatpack per definition

Paired
    one typed flatpack per leaf/entity

LargeGate
    one typed flatpack per family + leaf A/B + physical part 1/2

Garage
    one typed flatpack per family + START/MIDDLE/END role
```

All of those item types may still use the **same flatpack icon and the same vanilla `Flatpack` world model**. The type expresses transport identity; it does not express appearance.

This also keeps the dynamic data small. For a Simple door, modData can remain essentially durability/state only. Multipart families need only dynamic gameplay state that cannot be encoded by the stable typed parcel identity.

## Current V3 generic pilot — IMPLEMENTED BUT PAUSED

One generic engine item currently exists:

```text
Base.LMION_Flatpack
```

and White Panel Door currently routes through it using:

```text
lmionDoorDefinitionId
```

This code has **not been validated in game** and must not be treated as the chosen architecture.

Do not request a cold restart for it yet. First decide transport identity with the multisprite evidence above. If typed flatpacks are selected, revert the generic identity plumbing before the next game checkpoint and restore a typed White Panel transport item using the common flatpack visual.

## Likely typed-flatpack script shape

For a Simple door, one consolidated door script can still contain the transport item and Build engine components together:

```text
media/scripts/WhitePanelDoor.txt
    item LMION_WhitePanelDoor        -- typed flatpack transport identity
    xuiSkin                          -- Build UI
    entity WhitePanelDoor
        UiConfig
        CraftRecipe
        SpriteConfig
```

The item block can remain strict engine minimum. Definition-derived behavior remains in Lua.

For multipart families, one file per opening/family can contain all of its typed parcels rather than one file per physical parcel. For example:

```text
LargeWroughtIronGate.txt
    item ...A_Part1
    item ...A_Part2
    item ...B_Part1
    item ...B_Part2
    ...Build engine components...
```

and:

```text
GreenGarageDoor.txt
    item ..._Part1   -- START
    item ..._Part2   -- MIDDLE
    item ..._Part3   -- END
    ...Build engine components...
```

So choosing typed items does **not** require returning to Legacy's proliferation of `_Item.txt` / `_ParcelItems.txt` files.

## Decision checkpoint before code changes

Compare these two architectures:

```text
A. universal flatpack
   identity = modData
   visual = shared flatpack
   fewer script item declarations
   more custom identity matching at multisprite vanilla boundaries

B. typed flatpacks
   identity = item full type
   visual = shared flatpack
   more small item declarations
   simpler/existing exact matching for Simple + Garage + LargeGate
```

Based on recovered Legacy behavior, **B currently has the stronger evidence and lower integration risk**, but no implementation should be changed until this review is accepted.

## Existing generic-pilot commits

```text
634477b60912d4afb3d0a5c3c0f3901be4ea3d78  Add flatpack definition identity transport
a890e6e8461b4c99dcdd57ec87d1323d8eb0e811  Add Simple flatpack service
f71949ccd9328b4a583fe9b8d4604b440acc4eb0  Use generic flatpack for Simple pilot
52e6478f28b682376227c6614fb2d4b4db8c94a9  Route Simple pickup through generic flatpack
d65bb39e003386e6db6e09ecaad0c7d1f8b9a467  Add generic LMION flatpack item
5269fb6f012ac794efce7f1c128feeed9bfbb036  Keep White Panel script Build-only
b6e225af4bb4bf62c5772072841ef78ef4a558bb  Translate generic LMION flatpack
69dd3195fa95c633c994be225c6098332a50bc31  Keep generic flatpack inventory identity
826193b142120f2492df41c9de7dd62d8206630f  Preserve world door Moveables naming
```

Sources: Legacy `WhitePanelDoor_Item.txt`, `LargeWroughtIronGate_ParcelItems.txt`, `GreenGarageDoor_ParcelItems.txt`, `LargeGateSpecs.lua`, `LargeGateMoveables.lua`, `GarageDoorSpecs.lua`, `GarageDoorMoveables.lua`, plus active V3 Simple transport code.
