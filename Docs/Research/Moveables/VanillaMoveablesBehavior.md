# Vanilla Moveables behavior relevant to LMION V3

Status: **engine behavior researched; single-tile path validated in game; LargeGate transport identity correction implemented 2026-09-11 and awaiting re-test.**

## Principle

Keep vanilla Moveables responsible for its normal cursor, facing, timed action, tool/skill checks and item mechanics. LMION should intervene only where its opening identity, topology, placement rules, canonical `IsoDoor` result or transported state requires it.

Legacy is the functional reference. V3 may use different, simpler code but must reproduce the tested gameplay result.

## Useful vanilla control points

The validated Legacy / V3 single-tile path uses narrow `ISMoveableSpriteProps` boundaries:

```text
new(sprite)
-> attach LMION profile and canonical faces

pickUpMoveableInternal(...)
-> capture source durability before removal

instanceItem(...)
-> serialize transport state

canPlaceMoveableInternal(...)
-> preserve vanilla checks and add LMION placement rules

placeMoveableInternal(...)
-> let vanilla create the source object
-> canonicalize/finalize to IsoDoor
-> restore transported durability
```

These are evidence-backed control points, not a reason to copy old monolithic hook files.

## Moveable inventory identity

For a vanilla `Moveable`, the world sprite is part of the inventory identity.

Vanilla item creation performs the equivalent of:

```text
instanceItem(custom or generic moveable item)
-> item:ReadFromWorldSprite(spriteName)
```

The placement toolbar enumerates inventory Moveables and reconstructs props from:

```lua
ISMoveableSpriteProps.new(item:getWorldSprite())
```

The transaction/right-click placement path also reads `item:getWorldSprite()` before selecting facing and calling the Moveables placement path.

Therefore:

> A custom `base:moveable` transport item that is intended to use vanilla placement must carry a valid WorldSprite.

LMION modData is additional logical state. It does not replace this engine identity.

## LargeGate failure discovered 2026-09-11

Commit under test:

```text
5841a976ae8d2cf7f1928825fd266f76158c1b00
```

Observed in game:

```text
LargeGate pickup: parcels produced
inventory right-click placement: failed
Moveables toolbar placement: failed
```

The V3 LargeGate factory created `Base.LMION_OpeningParcel`, then stored definition/leaf/part/durability in modData, but did not call `ReadFromWorldSprite()`.

Because both placement frontends depend on `item:getWorldSprite()`, this generic-parcel implementation broke their common upstream identity path.

The correction is to restore the known-good Legacy model of segment-specific Moveable items and assign each parcel the canonical closed segment WorldSprite.

Do not attempt to compensate for a missing WorldSprite with separate UI-specific placement hacks.

## Sprite lifecycle

LMION configures known opening sprites after tile definitions are loaded. Runtime LargeGate SpriteGrids are also installed at this lifecycle point.

Code that depends on sprite properties or SpriteGrid membership must not assume those runtime changes exist before `OnLoadedTileDefinitions`.

## Transported state

Source Java representation is not gameplay state and is not serialized.

LMION transports logical durability through item modData:

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

Those fields complement the WorldSprite; they do not substitute for it.

## Development rule

Before changing a vanilla Moveables function, record:

- which exact vanilla boundary is involved;
- what vanilla already guarantees;
- the smallest LMION responsibility needed there;
- the Legacy behavior being reproduced;
- the load lifecycle requirement, if any;
- the concrete failure/reason when rejecting an action.

When behavior is uncertain, inspect the B42 game Lua / supplied JAR before adding an abstraction.
