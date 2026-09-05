# Transport appearance / flatpack — deferred

Status: **DECISION DEFERRED** as of 2026-09-05.

## Decision

Do **not** design or generalize flatpack appearance/identity now.

The current priority is functional opening behavior. Transport appearance will be revisited only after V3 has working runtime paths for the multipart families that constrain the design, especially:

```text
LargeGate
Garage
```

Until then, keep the already validated transport mechanism for the White Panel Simple pilot.

## Current validated Simple transport

The White Panel pilot uses:

```text
Base.LMION_WhitePanelDoor
```

as its technical `base:moveable` inventory item. This path has already been validated in game for:

- pickup;
- replacement;
- N/W rotation;
- standard-frame requirement;
- HP/max-HP persistence;
- canonical final `IsoDoor`.

No attempt should be made now to make this item's visual representation a flatpack.

## Why the appearance decision is postponed

Legacy multipart behavior shows that Garage and LargeGate transport has additional parcel/member semantics. That evidence is useful, but choosing a universal item, typed parcels, shared icon/model, or modData identity **before those V3 runtime paths exist** would optimize an unproven design.

The correct order is therefore:

```text
functional Simple runtime
-> functional Paired/FenceGate/Sliding as appropriate
-> functional LargeGate/Garage runtime
-> observe actual V3 parcel requirements
-> then decide transport appearance/flatpack representation
```

## Premature generic-flatpack experiment

A short-lived V3 experiment introduced:

```text
Base.LMION_Flatpack
Runtime/Moveables/DoorTransportIdentity.lua
Services/Moveables/SimpleDoorFlatpack.lua
```

with definition identity stored in modData.

This experiment was **never validated in game** and has been removed. Do not treat it as an architectural decision or resume it by default.

The restored code is the previously validated per-door Simple transport path.

## Rule for future work

When LargeGate and Garage runtime are working, revisit appearance as a separate concern:

```text
transport behavior / identity
!=
transport visual appearance
```

At that point compare the real V3 requirements rather than extrapolating from Simple alone.

Sources consulted during the deferred investigation: Legacy `WhitePanelDoor_Item.txt`, `LargeWroughtIronGate_ParcelItems.txt`, `GreenGarageDoor_ParcelItems.txt`, `LargeGateSpecs.lua`, `LargeGateMoveables.lua`, `GarageDoorSpecs.lua`, and `GarageDoorMoveables.lua`.
