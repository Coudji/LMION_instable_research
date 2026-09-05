# Flatpack transport — V3

Status: **HYPOTHÈSE / NON VALIDÉ** for the generic V3 item; Legacy behavior and B42 engine requirements recovered.

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

`InventoryItem` exposes `setName`, `setWeight`, `setActualWeight`, `setCustomWeight`, `getFullType` and modData access. V3 can therefore keep one engine item type while applying definition-specific display/weight/state at runtime.

## V3 pilot design

Use one engine item:

```text
Base.LMION_Flatpack
```

Its script owns only generic engine facts:

- `ItemType = base:moveable`;
- generic fallback weight;
- generic fallback name/translation;
- vanilla `Flatpack` world model;
- no per-door inventory icon.

Definition-specific facts remain outside the script:

```text
definitionId
pickup package weight
health / logical max-health
Moveables sprite/facing metadata created by vanilla
```

The flatpack stores `definitionId` explicitly in modData. Placement must verify that the item's stored definition matches the Simple profile resolved from the Moveables sprite metadata. This prevents a generic transport item from silently being interpreted as the wrong door.

## Pilot scope

The first generic-flatpack change remains restricted to:

```text
Doors.Wood.WhitePanelDoor
```

Do not activate every Simple definition merely because one generic item now exists. The previous pilot was implicitly gated by the existence of `Base.LMION_WhitePanelDoor`; V3 replaces that accidental gate with an explicit temporary pilot gate until the generic-flatpack path is validated in game.

After validation, remove the pilot gate and expand Simple support deliberately.

## Expected script shape after the pilot

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
-> replacement still rotates N/W
-> standard frame still required
-> definition identity matches
-> HP/max-HP still persist
-> final world object is IsoDoor
```

If this succeeds, one generic flatpack can replace the per-door technical item scripts for the Simple family. Multipart families may still need part/member metadata, but should reuse the same transport concept where their vanilla integration allows it.
