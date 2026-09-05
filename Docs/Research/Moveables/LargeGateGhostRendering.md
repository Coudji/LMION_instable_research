# LargeGate ghost rendering — V3 research

Status: **OBSERVÉ DANS LEGACY / WORKSHOP / VANILLA SOURCE**. V3 implementation should reproduce the behavior without adding rendering implementation fields to public definitions.

## Problem

A closed LargeGate leaf is physically two world members and must keep a two-square Moveables footprint. However the visible artwork is not represented the same way by every vanilla LargeGate family.

For most LargeGates, one of the two physical member sprites owns a `SpriteModel` that visually renders the complete leaf. If a custom preview blindly renders both physical sprites, part of the gate appears twice.

`LargeFarmGate` is the exception: its closed member sprites do not own such a complete-leaf `SpriteModel`, so both physical sprites must be rendered to obtain a complete ghost.

This is a rendering capability difference, not a semantic LargeGate subtype.

## OBSERVÉ DANS LEGACY — runtime SpriteGrid

Authoritative Legacy file:

```text
Legacy/Contents/mods/LMION_Pickup/42/media/lua/shared/LMION/Pickup/LargeGateRuntime.lua
```

At `OnLoadedTileDefinitions`, Legacy installs one exact two-member `IsoSpriteGrid` for every closed leaf/facing:

```text
N -> 2 x 1
W -> 1 x 2
```

Both closed member sprites receive the same grid through `sprite:setSpriteGrid(grid)`.

This lets vanilla Moveables understand one LargeGate leaf as a two-square multisprite object. The grid is engine topology used by the cursor and inventory lookup; it is not public LMION semantic definition data.

Open LargeGate sprites deliberately do not receive this fake closed grid because vanilla DoubleDoor open geometry occupies different squares.

## OBSERVÉ DANS VANILLA SOURCE — cursor behavior

`ISMoveableCursor.render()` enters `renderSpriteGrid()` when both original and current Moveables props are multisprite.

Vanilla `renderSpriteGrid()`:

1. gets the original/current `IsoSpriteGrid`;
2. computes the grid top-left from the selected member;
3. renders the floor footprint for every grid square;
4. renders every sprite in the grid with `RenderGhostTileColor`.

Therefore the runtime SpriteGrid is sufficient for footprint/rotation, but blindly using vanilla object rendering can be wrong when one member's SpriteModel already renders the complete leaf.

## OBSERVÉ DANS LEGACY — resolved closed ghost

Authoritative Legacy file:

```text
Legacy/Contents/mods/LMION_Pickup/42/media/lua/server/LMION/Pickup/LargeGateCursor.lua
```

Legacy narrowly overrides `ISMoveableCursor.renderSpriteGrid()` only when both move props belong to a LargeGate.

It always renders the full two-square floor footprint.

For most families it renders only one known complete-artwork member (`visualPartIndex`).

For `LargeFarmGate`, Legacy marks the leaf `previewAllParts = true` and renders both members.

This fixes both failure modes:

```text
normal LargeGate + render both -> duplicated artwork
LargeFarmGate + render one      -> incomplete artwork
```

Unknown/non-LargeGate grids delegate unchanged to vanilla.

## OBSERVÉ DANS WORKSHOP V2 — dynamic capability detection

Old Workshop file:

```text
Workshop/Contents/mods/LMION_Pickup/42/media/lua/server/LMION/Pickup/LargeGate/LargeGateCursor.lua
```

The later V2 implementation removed the family hard-code from preview selection. It probes a temporary `IsoObject` and calls `getSpriteModel()` to determine whether the physical sprite already owns model artwork.

Its preview rule is effectively:

```text
if a physical member owns the complete SpriteModel
    render that owner only
else
    render both physical members
```

This automatically selects the FarmGate behavior because its relevant sprites have no SpriteModel.

The same source tree's `LargeGateToolbar.lua` preserves vanilla `ISMoveableCursor`; it does not replace the toolbar with a second placement engine.

## B42.20.3 SpriteModel evidence

The supplied `spriteModels.txt` confirms the capability difference.

Closed model-owner sprites exist for the ordinary LargeGate families, including:

```text
LargeWroughtIronGate      33, 34, 40, 43
LargeHardenedWoodenGate  49, 50, 56, 59
DoubleWireGate            65, 66, 72, 75
DoubleFenceGate           81, 82, 88, 91
DoubleDoor                97, 98, 104, 107
```

There are no model entries for the `LargeFarmGate` closed range `112..127`.

This is why the same visual rule cannot be hard-coded as "always one sprite" or "always two sprites".

## V3 decision

Do **not** add fields such as:

```text
previewAllParts
visualPartIndex
```

to public LargeGate definitions.

The definition already states the physical geometry. Whether one PZ sprite owns complete visual artwork is an engine/rendering fact that V3 can discover at runtime.

V3 should use:

```text
LargeGate definition geometry
-> closed two-member runtime SpriteGrid
-> PZ SpriteModel capability probe
-> preview member selection
```

Expected rule:

```text
exactly one member exposes a SpriteModel -> render that member only
no member exposes a SpriteModel          -> render both members
ambiguous/unexpected model topology      -> targeted DEV diagnostic + safe explicit fallback
```

The footprint is always both physical members.

## V3 responsibilities

Proposed narrow files:

```text
Services/Moveables/LargeGateProfiles.lua
    derive family/leaf/part/facing/item identity from effective definitions

Runtime/Moveables/LargeGateSpriteGrids.lua
    install closed two-member SpriteGrids at OnLoadedTileDefinitions

PZ/SpriteModel.lua
    answer one engine question: does this sprite produce a SpriteModel?

Services/Moveables/LargeGateGhostParts.lua
    choose which physical closed members must be visually rendered

Hooks/Moveables/LargeGateCursor.lua
    own only the LargeGate-specific ISMoveableCursor rendering boundaries
```

`Hooks/Moveables/LargeGateCursor.lua` may own `ISMoveableCursor.renderSpriteGrid` because no current V3 file owns that method. Unknown/non-LargeGate grids must delegate to the previous implementation.

Open-state footprint handling should remain separate because open sprites deliberately do not carry the closed leaf SpriteGrid.

## Load timing

Runtime closed SpriteGrid installation belongs at:

```text
OnLoadedTileDefinitions
```

This matches the authoritative working Legacy lifecycle. Do not relocate it to ordinary Lua load or `OnGameBoot` without new evidence.

Cursor monkey patches are installed once during normal LMION Lua bootstrap.

Because changing SpriteGrid topology and adding Moveables hooks can leave stale runtime objects/cursors, the first integrated LargeGate validation requires a cold restart.

## Representative validation pair

One family is not sufficient to validate the ghost rule. Use two LargeGate pilots:

```text
LargeGates.Metal.LargeWroughtIronGate
    -> SpriteModel-owned artwork path
    -> ghost must not duplicate a member

LargeGates.Metal.LargeFarmGate
    -> no SpriteModel owner
    -> ghost must render both physical members
```

If both pass, the rendering mechanism is type-level and can be applied to the other LargeGate definitions as data activation rather than separate rendering architecture.

## Other LargeGate contracts that remain part of the same runtime milestone

Ghost rendering is only the additional visual subtlety. Functional LargeGate V3 must still preserve the established contracts:

```text
pickup one leaf only
-> two parcels, one per physical member

placement
-> requires the two compatible member parcels
-> inventory + nearby floor compatibility where Legacy supports it
-> N/W rotation
-> final members are IsoDoor
-> HP/max HP survive

leaf identity
-> stable A / B

Build
-> supported vanilla LargeGate construction is split A and B
```

Open-state pickup/replacement must also respect vanilla DoubleDoor topology; authoritative Legacy treats open geometry separately rather than faking the closed SpriteGrid onto open sprites.
