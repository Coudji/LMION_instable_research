# Paired 1x1 door pilot — V3 control points

Status: **VALIDÉ EN JEU** for the Blue Church pilot on 2026-09-05. The user reports the complete pilot is functional; small behavior/polish details may still need adjustment and are not considered final release validation.

Pilot:

```text
Doors.Wood.BlueChurchDoubleDoor
├─ left  -> Base.BlueChurchDoubleDoorLeft
└─ right -> Base.BlueChurchDoubleDoorRight
```

## Semantic contract

Paired is not LargeGate and is not vanilla's four-tile `DoubleDoor` SpriteGrid.

A Paired definition represents two independent physical 1x1 leaves that visually form one double-door set. Each leaf can be opened, picked up, transported, replaced and built independently.

The definition keeps explicit `left` / `right` members because that identity is meaningful for this family.

## OBSERVÉ DANS VANILLA / SOURCE

Legacy `DoorProfiles/PairedDoors.lua` records the runtime frame markers:

```text
left  -> DoubleDoor1
right -> DoubleDoor2
```

Legacy `Doors/Placement.lua` checks those markers on the target door frame and rejects a mismatched side.

Legacy `BlueChurchDoubleDoor.txt` defines two independent GameEntity SpriteConfigs, one for each leaf. There is no combined Paired SpriteGrid.

Legacy Build also exposes one CraftRecipe per leaf.

By contrast, B42.20.3 vanilla `entity_wood_doubledoor.txt` defines `Base.DoubleDoor` as a true four-tile SpriteConfig with `dontNeedFrame=true`. That vanilla structure is a different topology and must not be used to infer Paired behavior.

## V3 frame ownership

`PZ/DoorFrame.lua` owns only the PZ-level classification/query of door frames:

```text
standard
paired-left
paired-right
```

`PZ/StandardDoorFrame.lua` remains the Simple adapter for `standard`.

`PZ/PairedDoorFrame.lua` maps semantic Paired members to structural frame classes:

```text
left  -> paired-left  -> DoubleDoor1
right -> paired-right -> DoubleDoor2
```

`Runtime/DoorPlacement.lua` owns occupancy/vehicle/facing validation and exposes separate rules:

```text
canPlaceSimpleAt(...) -> standard frame
canPlacePairedAt(...) -> matching paired frame member
```

The public definition does not gain a `frameSide` property. Left/right geometry already supplies the semantic member; the frame consequence stays internal.

## Moveables control point

The vanilla path remains the already validated `ISMoveableSpriteProps` path:

```text
new
-> hasFaces/getFaces
-> pickUpMoveableInternal
-> instanceItem
-> canPlaceMoveableInternal
-> placeMoveableInternal
```

There is still exactly **one owner** for those monkey patches:

```text
Hooks/Moveables/SingleTileDoor.lua
```

It delegates profile derivation, placement rules, durability transport and finalization instead of adding a second Paired hook around the same vanilla methods.

Profile responsibilities:

```text
SingleEntityDoorProfiles.lua -> Simple/FenceGate/Sliding
PairedDoorProfiles.lua       -> Paired member profiles
SingleTileDoorProfiles.lua   -> resolve supported 1x1 profile by sprite
```

The Paired pilot remains intentionally restricted to `Doors.Wood.BlueChurchDoubleDoor`; validation of this pilot does not automatically validate every Paired definition.

Expected Moveables diagnostics include `type=Paired` and `member=left/right`.

## Build control point

There is also one owner for the intercepted vanilla Build methods:

```text
server/LMION/Hooks/Build/SingleTileDoor.lua
```

It owns the same three boundaries previously proven by White Panel:

```text
ISBuildIsoEntity.isValid
ISBuildIsoEntity.isValidPerSquare
ISBuildIsoEntity.setInfo
```

Unknown/non-LMION build objects always return to the previous implementation.

For supported V3 single-tile builds:

```text
GameEntity
-> EntityIndex
-> SingleTileDoorBuildProfile
-> family-specific placement rule
-> vanilla construction
-> SingleTileDoorFinalizer
-> canonical IsoDoor
```

`SingleTileDoorFinalizer` searches for the exact built GameEntity, canonicalizes the vanilla result to `IsoDoor`, computes durability from the LMION definition and clears fresh lock state through the existing canonicalization contract.

## Engine script pilot

`media/scripts/BlueChurchDoubleDoor.txt` contains the strict engine-facing data for both leaves in one file:

```text
2 moveable transport item declarations
2 XUI entries
2 CraftRecipe components
2 SpriteConfig components
```

The SpriteConfigs contain only explicit faces. Legacy `health` / `skillBaseHealth` values are deliberately not duplicated because V3 durability is definition-owned and finalized in Lua.

Build icons reuse:

```text
LMION/doors/BlueChurchDoubleDoorLeft
LMION/doors/BlueChurchDoubleDoorRight
```

## Vanilla preserved

Vanilla still owns:

- Build menu/cursor/timed action;
- Moveables pickup/place action lifecycle;
- skill/tool execution at the existing vanilla boundaries;
- inventory item creation/removal;
- initial world object creation.

LMION intervenes only for definition identity, explicit N/W faces, Paired frame-side validity, durability transport and canonical final `IsoDoor` representation.

## VALIDÉ EN JEU — 2026-09-05

The integrated cold-start checkpoint was exercised together with the White Panel regression, FenceGate pilot and Sliding pilot.

The user reports the Blue Church Paired path is functional, including the intended independent-leaf Build/Pickup/replacement flow and paired-frame behavior. No blocking regression was observed.

This validation means:

```text
Blue Church Paired pilot -> functional V3 runtime checkpoint
```

It does **not** mean:

```text
all Paired definitions validated
all metal Paired definitions validated
all polish/details finalized
release behavior frozen
```

The next expansion may reuse the validated Paired architecture, while remaining definitions should still be activated in controlled batches.