# Vanilla Moveables behavior relevant to V3 Simple 1x1

Status: recovered from Legacy research and known-good Legacy implementation; V3 hooks not installed yet.

## Vanilla behavior to preserve

For an ordinary single-sprite Moveable, Pickup produces one inventory item. This matches LMION Simple 1x1 doors and individual Paired 1x1 leaves.

The Moveables toolbar owns its normal cursor/ghost/facing interaction. V3 should preserve vanilla behavior and intervene only at the exact boundaries required for LMION door identity, durability, frame rules and canonical IsoDoor finalization.

## Known-good Legacy control points

The validated Legacy Simple-door path wrapped these `ISMoveableSpriteProps` boundaries:

```text
new(sprite)
-> attach LMION door profile / canonical N-W faces

pickUpMoveableInternal(...)
-> capture source door durability before vanilla removes it

instanceItem(...)
-> serialize captured durability into the resulting inventory item

canPlaceMoveableInternal(...)
-> apply LMION door/frame placement rules while preserving vanilla skill/tool checks

placeMoveableInternal(...)
-> let vanilla place first
-> locate/finalize the resulting door
-> restore transported durability
```

This is evidence for useful control points, not a requirement to copy the old V2 hook file wholesale.

## Sprite lifecycle

Legacy rebuilt its sprite-to-door mapping after tile definitions and marked known door sprites `IsMoveAble` at `Events.OnLoadedTileDefinitions`.

That lifecycle point is relevant because runtime sprite/SpriteConfig-derived state is not considered stable before tile definitions finish loading.

V3 must re-evaluate the smallest necessary equivalent only when the first Moveables hook is introduced.

## Inventory serialization

Legacy canonicalized an opening's inventory identity to the closed N/W SpriteConfig face while transporting logical durability in item modData:

```text
lmionDoorHealth
lmionDoorMaxHealth
lmionDoorMaxWasLogical
```

Source Java representation was intentionally not transported as gameplay state.

## Development rule for the next hook

Before changing a Moveables function, record:

- which vanilla function is wrapped;
- what vanilla still owns before/after the wrapper;
- the exact LMION reason for intervening;
- the previous/original function that remains authoritative;
- any load lifecycle requirement;
- targeted logs identifying the selected path and failure reason.

Source: Legacy `Research/Moveables/VanillaMoveablesBehavior.md` plus `Legacy/Contents/.../Pickup/Doors/Hooks.lua` and `Registry.lua`.
