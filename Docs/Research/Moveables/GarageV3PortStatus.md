# Garage V3 implementation checkpoint

Status: **implemented, in-game validation pending** (2026-09-11).

Legacy remains the behavioral oracle. Workshop/late Legacy is the resource/UI archaeology reference where it refined the Garage Build model.

## Implemented behavior

### Pickup / transport

- all 7 built-in Garage definitions are profile-driven;
- START / MIDDLE / END map to three technical moveable item types per family;
- complete native garage chains are resolved through `IsoDoor.getGarageDoorFirst/Next`;
- each physical member delegates pickup to vanilla `pickUpMoveableInternal()`;
- each parcel carries its own HP/maxHP state;
- there is no pickup-session pairing/batch identity.

### Replacement

Dedicated inventory placement:

- variable width, minimum L2;
- starts at the maximum length supported by available stock;
- maximum is bounded by `GarageLengthPolicy` unless Sandbox unlimited mode is active;
- configurable decrease/increase ModOptions keybinds, defaults numpad `-` / `+`;
- normal PZ `Rotate building` key toggles N/W;
- mouse-drag rotation is disabled;
- prevalidates the complete plan;
- creates the complete chain before consuming parcels;
- rolls back created members on create/finalization failure;
- consumes exactly 1 START + (L-2) MIDDLE + 1 END;
- inventory is searched before nearby floor stock;
- floor plans retain the exact selected `IsoWorldInventoryObject`, matching the validated LargeGate floor-consumption lesson;
- extra stock remains untouched.

Vanilla toolbar placement:

- keeps the vanilla Moveables L3 SpriteGrid/ghost;
- remains intentionally fixed L3;
- final placement is delegated to the same Garage placement plan instead of maintaining a second stock/consumption implementation.

### Build

- source SpriteConfig remains canonical static L3;
- base CraftRecipe is static L2;
- Build UI exposes direct `-` / `+` length controls;
- selected length survives quick-repeat;
- only the Build cursor sees a variable FaceInfo proxy;
- Sandbox Garage width policy is shared with replacement;
- Build stock includes player inventory, Build UI containers and ground items;
- MetalBar and IronBar share one native variable quota and may be mixed;
- native selected bar quota is synchronized to selected Garage length;
- Build is blocked when selected native bars do not cover L;
- LMION consumes only the resource delta not already consumed by vanilla;
- material metadata records actual non-drainable LMION extras.

Variable costs for length L:

```text
MetalBar/IronBar combined = L
Hinge                     = 2L
solid SmallSheetMetal      = 3L
glazed SmallSheetMetal     = 2L
glazed GlassPanel          = L
BlowTorch uses             = min(ceil(L/3), 10)
WeldingRods uses           = min(2*ceil(L/3), 20)
```

The native bar input may already consume anywhere from its L2 minimum up to L. LMION therefore charges only:

```text
max(0, L - bars already consumed by vanilla)
```

## Hook ownership

Garage does not add a competing global Moveables constructor owner. The existing shared `ISMoveableSpriteProps.new` owner applies Garage identity alongside SingleTile and LargeGate identities.

Build finalization now has one `ISBuildIsoEntity.setInfo` owner in:

```text
LMION/Hooks/Build/DoorSetInfo.lua
```

It dispatches only the family-specific finalization work. Family hooks keep their distinct validation/cursor/resource responsibilities.

## Commits

```text
472f9712  Add Garage profiles and script data
11c66697  Correct Garage SpriteConfig geometry
89fb89d3  Add Garage Moveables runtime services
b471bc86  Integrate Garage pickup with shared Moveables hooks
4bbe2cd6  Add Garage inventory and toolbar placement
5f9c64ec  Add variable Garage Build resource model
6be62602  Add Garage Build width UI and key options
150fa63a  Harden Garage SpriteGrid and parcel handling
64aabed1  Restore Garage placement and Build safety guards
054e947c  Centralize door Build finalization hook
```

## Required cold-start validation

Scripts changed, so test from a cold restart.

Build:

- solid + glazed Garage;
- L2, L3, L6;
- N/W;
- `-` / `+` selector;
- displayed requirements match selected L;
- exact resource consumption;
- mixed MetalBar/IronBar;
- inventory/container/ground stock;
- quick-repeat preserves L;
- default Sandbox cap L6;
- optionally higher cap/unlimited later.

Pickup/replacement:

- pickup L3 and L6, closed and open if practical;
- inventory Place variable width and N/W rotation;
- toolbar Place fixed L3;
- mixed inventory/floor START/MIDDLE/END in more than one arrangement;
- pickup L6 -> place L3 -> exactly 3 surplus parcels remain;
- damaged member HP/maxHP survives;
- final chain is functional and canonical `IsoDoor`;
- no selected floor parcel remains after successful placement.

Until these tests pass, Garage V3 is **implemented, not validated**.
