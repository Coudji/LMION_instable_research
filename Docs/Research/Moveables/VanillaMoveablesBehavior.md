# Vanilla Moveables behavior relevant to LMION V3

Status: **engine behavior researched; single-tile path validated; LargeGate mixed inventory/floor replacement and floor-parcel consumption validated on 2026-09-11.**

## Principle

Keep vanilla Moveables responsible for its normal cursor, facing, timed action, tool/skill checks and item lifecycle. LMION should intervene only where opening identity, topology, placement rules, canonical `IsoDoor` output or transported state requires it.

Legacy is the functional reference. V3 may use different, simpler code but must reproduce the tested gameplay result.

## Shared vanilla boundaries

Useful control points are:

```text
new(sprite)
-> attach LMION profile / canonical faces

pickUpMoveableInternal(...)
-> vanilla creates/delivers the Moveable and removes the source
-> LMION captures transport state around that boundary

instanceItem(...)
-> vanilla creates the custom Moveable and calls ReadFromWorldSprite
-> LMION adds identity/durability metadata

canPlaceMoveableInternal(...)
-> preserve vanilla checks and add LMION placement rules

placeMoveableInternal(...)
-> let vanilla create the source object
-> LMION canonicalizes/finalizes to IsoDoor and restores state
```

One boundary should have one owner. LargeGate must extend the existing Moveables boundary owner rather than install another wrapper around `instanceItem` or `pickUpMoveableInternal`.

## Moveable inventory identity

For a vanilla `Moveable`, the world sprite is part of inventory identity.

Vanilla item creation follows:

```text
instanceItem(custom or generic Moveable item)
-> item:ReadFromWorldSprite(spriteName)
```

The toolbar reconstructs props from `item:getWorldSprite()`. The inventory/right-click transaction path also uses the WorldSprite before entering placement.

Therefore a custom `base:moveable` transport item intended for vanilla placement must carry a valid WorldSprite. LMION modData complements that engine identity; it does not replace it.

## LargeGate failure 1: generic parcel without WorldSprite

Commit under test:

```text
5841a976ae8d2cf7f1928825fd266f76158c1b00
```

Observed:

```text
LargeGate pickup produced parcels
inventory right-click placement failed
toolbar placement failed
```

The V3 factory created generic `Base.LMION_OpeningParcel` items with LMION identity in modData but no WorldSprite.

**DO NOT REINTRODUCE:** a generic multipart package that removes the engine-visible segment identity.

The correction restored segment-specific items and the canonical closed segment WorldSprite.

## 2026-09-11 placement result after WorldSprite correction

On commit `b92705e6de424b486a4d32ba53daab9e175c476d`, Project Zomboid 42.20.4 successfully placed a DoubleWireGate leaf through both toolbar and right-click placement.

The tested mixed source set was:

```text
part 1 -> nearby floor
part 2 -> inventory
```

Both members were created/finalized and the resulting leaf was functional. This proved mixed inventory/floor lookup and frontend bootstrap.

The remaining defect was that the part-1 floor parcel stayed in the world even though LMION logged placement completed.

## Floor consumption behavior

Vanilla multisprite placement supports items coming from inventory or nearby floor. Its floor branch uses the same removal sequence as validated Legacy:

```text
worldItem = item:getWorldItem()
worldItem:getSquare():transmitRemoveItemFromSquare(worldItem)
worldItem:getSquare():removeWorldObject(worldItem)
item:setWorldItem(nil)
```

The defect was not evidence that these engine calls were wrong. The selected floor parcel itself was already proven correct because its durability reached the placed member.

The validated V3 correction is to preserve **the exact `IsoWorldInventoryObject` selected during floor lookup** inside the placement plan and consume that exact reference after placement/finalization. Re-resolving the world object from the `InventoryItem` after placement is not reliable enough for this transaction.

The previously failing arrangement, Part2 in inventory + Part1 on the floor, now consumes both parcels correctly in game. The inverse arrangement also works.

## LargeGate stock-selection rule

Part1 and Part2 are independent required stock entries. Placement does not bind them to the same pickup session and does not give the item that launched the cursor special priority.

The V3 `preferred` path was removed. Each part is resolved independently from inventory first, then nearby floor, following the Legacy gameplay model. Per-parcel durability travels with the selected parcel.

## Critical Legacy / Workshop difference: LargeGate pickup lifecycle

Known-good Legacy LargeGate pickup resolves the two physical members, then delegates each member to vanilla:

```lua
moveProps.isMultiSprite = true
moveProps:pickUpMoveableInternal(...)
```

Vanilla therefore owns:

```text
custom Moveable creation
ReadFromWorldSprite
component transfer
AddWorldInventoryItem for multisprite pickup
source-object removal
```

Workshop changed this boundary. Its `MultiSquarePickupInternal` manually created the item, manually added the world item and manually removed the door segment. The original V3 LargeGate implementation independently recreated the same type of manual lifecycle with `LargeGateParcelFactory` + `MoveableDoorSegmentPickup`.

The exact floor-consumption defect was ultimately corrected by preserving the selected floor world-object reference, not by changing vanilla removal semantics. Even so, the architectural comparison remains important:

> Legacy delegates the physical Moveable pickup lifecycle to vanilla; Workshop/V3 manually recreated it.

V3 now follows the vanilla `pickUpMoveableInternal()` boundary per LargeGate member. LMION only captures/writes its semantic identity and durability around the already-owned vanilla boundaries.

**DO NOT REINTRODUCE BY DEFAULT:** a custom generic helper that replaces vanilla multipart Moveable pickup when the Legacy path proves vanilla can own it.

## Sprite lifecycle

LMION configures known opening sprites after tile definitions are loaded. Runtime LargeGate SpriteGrids are also installed at that lifecycle point.

Code depending on sprite properties or SpriteGrid membership must not assume those runtime changes exist before `OnLoadedTileDefinitions`.

## Transported state

LMION transports durability through item modData:

```text
lmionDoorHealth
lmionDoorMaxHealth
lmionDoorMaxWasLogical
```

LargeGate additionally transports internal segment identity:

```text
lmionLargeGateDefinitionId
lmionLargeGateLeaf
lmionLargeGatePart
```

These fields are logical state, not replacements for PZ Moveable identity.

## Version note

The supplied local JAR/scripts used for bytecode/source checks are B42.20.3. The 2026-09-11 runtime log reports the user's game as B42.20.4.

If an engine behavior differs from the currently inspected vanilla source/JAR, obtain/check the exact 42.20.4 game file before inventing a compatibility workaround.

## Development rule

Before changing a vanilla Moveables boundary, record:

- the exact vanilla method involved;
- what vanilla already guarantees;
- the smallest LMION responsibility needed there;
- the Legacy behavior being reproduced;
- any load lifecycle requirement;
- the concrete failure reason/log when rejecting an action.

When uncertain, inspect current game Lua/JAR instead of layering another abstraction over an assumption.
