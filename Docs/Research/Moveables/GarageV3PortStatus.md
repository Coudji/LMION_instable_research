# Garage V3 implementation checkpoint

Status: **core Build + pickup + variable replacement validated in game** (2026-09-12). Broader catalog/resource/edge-case validation is still pending.

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

Pickup rendering:

- the synthetic L3 SpriteGrid remains a technical vanilla Moveables adapter only;
- Garage pickup rendering uses the actual native START/MIDDLE*/END chain footprint instead of exposing that fixed L3 technical grid.

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

## In-game validation — 2026-09-12

Tested on Project Zomboid 42.20.4 with `GarageDoors.GreenGarageDoor`.

Confirmed:

```text
Build succeeds for Garage L3 and L6
pickup L3 succeeds when skill requirement is met/bypassed
pickup L6 succeeds
replacement L3 succeeds
replacement from L6 stock responds correctly to width +/- controls
variable replacement creates the requested Garage width correctly
post-placement ISMoveablesAction sound-context error is fixed
```

The initial apparent pickup failure was not a Garage chain failure: the test character had MetalWelding 2 while the Garage pickup definition requires MetalWelding 3. Enabling Moveables cheat confirmed the pickup path itself worked.

A real rendering defect was also observed on L6 pickup: the fixed technical L3 SpriteGrid appeared as the highlighted pickup footprint. Commit `3ab07fc740e809fc40c6800bc61ae7c4c72d175c` changed pickup rendering to use the complete native Garage chain instead.

A separate replacement error occurred after otherwise successful placement:

```text
attempted index: getSoundFromTool of non-table: null
ISMoveablesAction.setActionSound
```

Cause: the V3 dedicated Garage placement action had omitted the normal Moveables context fields that Legacy supplied (`moveProps`, `origMoveProps`, `origSpriteName`). Commit `3fcb7e90043e235c8974206bb708855a289ed730` restored them. User retest: **works**.

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
3ab07fc7  Render full Garage chain during pickup
3fcb7e90  Restore Garage placement action Moveables context
```

## Validation still required

The core Garage variable workflow is now proven, but the following matrix has not yet all been explicitly validated:

Build:

- glazed Garage;
- exact resource consumption outside Build cheat;
- mixed MetalBar/IronBar;
- inventory/container/ground stock;
- quick-repeat preserves L;
- Sandbox higher cap/unlimited.

Pickup/replacement:

- all 7 Garage families;
- both N/W orientations as an explicit matrix;
- open Garage pickup/replacement;
- toolbar Place fixed L3 as a dedicated checkpoint;
- mixed inventory/floor START/MIDDLE/END in multiple arrangements;
- pickup L6 -> place L3 -> exactly 3 surplus parcels remain;
- damaged member HP/maxHP survival;
- exact floor-parcel consumption;
- rollback/failure paths.

Do not downgrade the proven core workflow back to “not implemented”: Build, L3/L6 pickup, variable width controls and successful replacement are now in-game validated.