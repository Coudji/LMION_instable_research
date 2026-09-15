# Garage V3 implementation checkpoint

Status: **core Build + pickup + variable replacement validated in game** (2026-09-12). Broader catalog/resource/edge-case validation is still pending.

Legacy remains the behavioral oracle. Workshop/late Legacy is the resource/UI archaeology reference where it refined the Garage Build model.

## Terminology

The active V3 term for the variable START/MIDDLE*/END span is **width**.

This is the same concept in both N and W facing. Rotation changes the world axis, not the semantic name of the Garage dimension. Historical notes that used `length` refer to this same width and should not be copied into new code.

Active names include:

```text
GarageWidthPolicy
GarageWidthState
GarageWidthSelector
GarageMaxWidth
lmionGarageWidth
plan.width
selectedWidth
```

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

- variable width, minimum W2;
- starts at the maximum width supported by available stock;
- maximum is bounded by `GarageWidthPolicy` unless Sandbox unlimited mode is active;
- configurable decrease/increase ModOptions keybinds, defaults numpad `-` / `+`;
- normal PZ `Rotate building` key toggles N/W;
- mouse-drag rotation is disabled;
- prevalidates the complete plan;
- creates the complete chain before consuming parcels;
- rolls back created members on create/finalization failure;
- consumes exactly 1 START + (W-2) MIDDLE + 1 END;
- inventory is searched before nearby floor stock;
- floor plans retain the exact selected `IsoWorldInventoryObject`, matching the validated LargeGate floor-consumption lesson;
- extra stock remains untouched.

Vanilla toolbar placement:

- keeps the vanilla Moveables width-3 SpriteGrid/ghost;
- remains intentionally fixed width 3;
- final placement is delegated to the same Garage placement plan instead of maintaining a second stock/consumption implementation.

Pickup rendering:

- the synthetic width-3 SpriteGrid remains a technical vanilla Moveables adapter only;
- Garage pickup rendering uses the actual native START/MIDDLE*/END chain footprint instead of exposing that fixed technical grid.

### Build

- source SpriteConfig remains canonical static width 3;
- base CraftRecipe is static width 2;
- Build UI exposes direct `-` / `+` width controls;
- selected width survives quick-repeat;
- only the Build cursor sees a variable FaceInfo proxy;
- Sandbox Garage width policy is shared with replacement;
- Build stock includes player inventory, Build UI containers and ground items;
- MetalBar and IronBar share one native variable quota and may be mixed;
- native selected bar quota is synchronized to selected Garage width;
- Build is blocked when selected native bars do not cover W;
- LMION consumes only the resource delta not already consumed by vanilla;
- material metadata records actual non-drainable LMION extras.

Variable costs for width W:

```text
MetalBar/IronBar combined = W
Hinge                     = 2W
solid SmallSheetMetal      = 3W
glazed SmallSheetMetal     = 2W
glazed GlassPanel          = W
BlowTorch uses             = min(ceil(W/3), 10)
WeldingRods uses           = min(2*ceil(W/3), 20)
```

The native bar input may already consume anywhere from its width-2 minimum up to W. LMION therefore charges only:

```text
max(0, W - bars already consumed by vanilla)
```

## Hook ownership

Garage does not add a competing global Moveables constructor owner. The existing shared `ISMoveableSpriteProps.new` owner applies Garage identity alongside SingleTile and LargeGate identities.

Build finalization has one `ISBuildIsoEntity.setInfo` owner in:

```text
LMION/Hooks/Build/DoorSetInfo.lua
```

It dispatches only the family-specific finalization work. Family hooks keep their distinct validation/cursor/resource responsibilities.

## In-game validation — 2026-09-12

Tested on Project Zomboid 42.20.4 with `GarageDoors.GreenGarageDoor`.

Confirmed:

```text
Build succeeds for width 3 and width 6
pickup width 3 succeeds when skill requirement is met/bypassed
pickup width 6 succeeds
replacement width 3 succeeds
replacement from width-6 stock responds correctly to width +/- controls
variable replacement creates the requested Garage width correctly
post-placement ISMoveablesAction sound-context error is fixed
```

The initial apparent pickup failure was not a Garage chain failure: the test character had MetalWelding 2 while the Garage pickup definition requires MetalWelding 3. Enabling Moveables cheat confirmed the pickup path itself worked.

A real rendering defect was also observed on width-6 pickup: the fixed technical width-3 SpriteGrid appeared as the highlighted pickup footprint. Commit `3ab07fc740e809fc40c6800bc61ae7c4c72d175c` changed pickup rendering to use the complete native Garage chain instead.

A separate replacement error occurred after otherwise successful placement:

```text
attempted index: getSoundFromTool of non-table: null
ISMoveablesAction.setActionSound
```

Cause: the V3 dedicated Garage placement action had omitted the normal Moveables context fields that Legacy supplied (`moveProps`, `origMoveProps`, `origSpriteName`). Commit `3fcb7e90043e235c8974206bb708855a289ed730` restored them. User retest: **works**.

## Validation still required

The core Garage variable workflow is proven, but the following matrix has not yet all been explicitly validated:

Build:

- glazed Garage;
- exact resource consumption outside Build cheat;
- mixed MetalBar/IronBar;
- inventory/container/ground stock;
- quick-repeat preserves width;
- Sandbox higher cap/unlimited.

Pickup/replacement:

- all 7 Garage families;
- both N/W orientations as an explicit matrix;
- open Garage pickup/replacement;
- toolbar Place fixed width 3 as a dedicated checkpoint;
- mixed inventory/floor START/MIDDLE/END in multiple arrangements;
- pickup width 6 -> place width 3 -> exactly 3 surplus parcels remain;
- damaged member HP/maxHP survival;
- exact floor-parcel consumption;
- rollback/failure paths.

Do not downgrade the proven core workflow back to “not implemented”: Build, width-3/width-6 pickup, variable-width controls and successful replacement are now in-game validated.
