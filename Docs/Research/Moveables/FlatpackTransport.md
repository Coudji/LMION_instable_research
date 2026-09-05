# Flatpack transport — V3

Status: **HYPOTHÈSE / NON VALIDÉ** in game for the generic V3 pilot; implementation is present for White Panel Door.

## Product rule

A picked-up door is transported as a **flatpack**. The inventory representation is not a visual copy of the door and must not require one inventory item script/icon per door definition.

World/build identity and transport identity are separate:

```text
world door
-> LMION definitionId
-> generic flatpack item + transport metadata
-> replacement
-> canonical IsoDoor
```

## OBSERVÉ DANS LEGACY

Legacy used one `ItemType = base:moveable` script item per Simple door. Example `Base.LMION_WhitePanelDoor` contained only moveable item metadata and a per-door weight. The Moveables hook then set `moveProps.customItem` to that per-door item type and let vanilla `instanceItem()` create the inventory object.

Legacy transported door health/max-health in item modData. The source Java representation was deliberately not transported; placement converged to canonical `IsoDoor`.

This per-door item catalog is behavioral evidence that vanilla needs a valid moveable script item at the `customItem` boundary. It is **not** evidence that the item type itself must be unique per door.

## OBSERVÉ DANS VANILLA / SOURCE

B42.20.3 script data contains the vanilla model:

```text
model Flatpack
{
    mesh = WorldItems/Flatpack,
    scale = 0.175,
}
```

Therefore LMION can use the vanilla `Flatpack` world model without shipping a duplicate door inventory texture/model.

`InventoryItem` exposes `setName`, `setWeight`, `setActualWeight`, `setCustomWeight`, `getFullType` and modData access. V3 can therefore keep one engine item type while applying definition-specific weight/state at runtime.

## Implemented V3 pilot

One engine item now exists:

```text
Base.LMION_Flatpack
```

`media/scripts/Flatpack.txt` owns only generic engine facts:

```text
ItemType = base:moveable
Icon = default
fallback Weight = 1.0
WorldStaticModel = Flatpack
Tags = base:usedisplayname
```

The fallback weight is not gameplay data. `SimpleDoorFlatpack.prepare()` replaces it with the effective definition package weight on the created inventory item.

`WhitePanelDoor.txt` no longer declares `item LMION_WhitePanelDoor`; it now contains only the Build-facing XUI/CraftRecipe/SpriteConfig data PZ needs before Lua.

Definition-specific transport facts remain outside the script:

```text
definitionId
pickup package weight
health / logical max-health
Moveables sprite/facing metadata created by vanilla
```

### Transport identity

`Runtime/Moveables/DoorTransportIdentity.lua` owns one modData fact:

```text
lmionDoorDefinitionId
```

It can write, read and compare that definition identity only.

`Services/Moveables/SimpleDoorFlatpack.lua` owns the Simple flatpack use case:

```text
prepare generic item
-> write definition identity
-> delegate durability-state serialization
-> restore generic Flatpack display name
-> apply definition package weight
```

Placement accepts the generic item only when its stored definition ID matches the Simple profile resolved from the current Moveables sprite metadata. The per-frame validity path rejects mismatches silently; the actual placement boundary logs a stable `flatpack-identity` rejection if it is somehow reached with the wrong parcel.

### Hook ownership

`Hooks/Moveables/SimpleDoor.lua` still owns the same narrow vanilla boundaries. It now delegates item preparation and identity matching to `SimpleDoorFlatpack` rather than treating a per-door script item type as identity.

The world Moveables name is no longer overwritten from the generic flatpack script item, so a world door does not become named `Flatpack` merely because that is its transport representation.

## Pilot scope

The generic-flatpack implementation remains explicitly restricted to:

```text
Doors.Wood.WhitePanelDoor
```

Do not activate every Simple definition merely because the generic item exists. The previous pilot was implicitly gated by the existence of `Base.LMION_WhitePanelDoor`; V3 replaces that accidental gate with an explicit temporary pilot gate until the generic-flatpack path is validated in game.

After validation, remove the pilot gate and expand Simple support deliberately.

## Current script shape

```text
media/scripts/Flatpack.txt
    -> one generic transport item

media/scripts/WhitePanelDoor.txt
    -> Build XUI + CraftRecipe + SpriteConfig only
```

No `item LMION_WhitePanelDoor` block remains.

## Validation target

Next meaningful cold-start checkpoint:

```text
Build White Panel Door
-> damage it
-> Pickup
-> inventory item full type = Base.LMION_Flatpack
-> inventory name = Flatpack
-> replacement still rotates N/W
-> standard frame still required
-> definition identity matches
-> HP/max-HP still persist
-> final world object is IsoDoor
```

Expected serialization log:

```text
[LMION:DEV] Simple flatpack serialized: definition=Doors.Wood.WhitePanelDoor item=Base.LMION_Flatpack prepared=true
```

If this succeeds, one generic flatpack can replace the per-door technical item scripts for the Simple family. Multipart families may still need part/member metadata, but should reuse the same transport concept where their vanilla integration allows it.

## Implementation commits

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
