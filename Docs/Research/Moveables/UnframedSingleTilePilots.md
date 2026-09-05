# FenceGate + Sliding 1x1 pilots — V3

Status: **VALIDÉ EN JEU** for the two pilots on 2026-09-05. The user reports both paths are functional; small behavior/polish details may still need adjustment and are not considered final release validation.

Pilots:

```text
FenceGates.Wood.SmallWhiteWoodenGate
SlidingDoors.BrownSlidingGlassDoor
```

## Shared topology

Both families are one physical tile with explicit N/W closed/open faces. They share the same vanilla Moveables lifecycle already proven by Simple, but their semantic placement contract is different:

```text
Simple    -> standard frame required
FenceGate -> no frame
Sliding   -> no frame
```

They remain distinct `doorType` values. V3 does not infer FenceGate/Sliding semantics from geometry or from `dontNeedFrame`.

## OBSERVÉ DANS VANILLA / SOURCE — FenceGate

Legacy `SmallWhiteWoodenGate.txt` defines `Base.SmallWhiteWoodenGate` with one SpriteConfig and:

```text
dontNeedFrame = true
```

Legacy Build exposes the same GameEntity through one CraftRecipe.

The active V3 definition independently states the gameplay facts:

```text
doorType = FenceGate
pickup: Woodwork 1 + crowbar
replacement: hammer
package weight: 7
```

The V3 script keeps `dontNeedFrame = true` only because vanilla Build needs that engine-time SpriteConfig fact before Lua placement rules run. It is not copied into the public definition.

## OBSERVÉ DANS VANILLA / SOURCE — Sliding

Legacy `BrownSlidingGlassDoor.txt` likewise defines one SpriteConfig with:

```text
dontNeedFrame = true
```

The active V3 definition remains semantic `doorType = Sliding` and owns MetalWelding construction/pickup facts.

The Build script follows the V3 definition's material alternative:

```text
2 x [Base.MetalBar;Base.IronBar]
```

rather than silently narrowing back to the older Legacy MetalBar-only recipe.

## Metal Moveables tool boundary

Legacy deliberately registered custom Moveables tool definitions for metal openings:

```text
LMIONMetalScrewdriver -> Base.Screwdriver -> Perks.MetalWelding
LMIONMetalCrowbar     -> crowbar          -> Perks.MetalWelding
LMIONMetalHammer      -> Base.Hammer      -> Perks.MetalWelding
```

This prevents a physical screwdriver/crowbar/hammer from accidentally selecting vanilla's Woodwork-governed Moveables tool definition for a metal opening.

V3 restores this narrow engine bridge in:

```text
Runtime/Moveables/ToolDefinitions.lua
```

`SingleTileProfileFields` chooses the normal vanilla tool definition for Woodwork profiles and the LMION metal definition when the governing pickup skill is `MetalWelding`.

The Brown Sliding Glass Door pilot exercised this bridge successfully in the 2026-09-05 integrated checkpoint.

## Hook ownership

FenceGate and Sliding do not install new monkey patches.

Moveables owner:

```text
Hooks/Moveables/SingleTileDoor.lua
```

Build owner:

```text
server/LMION/Hooks/Build/SingleTileDoor.lua
```

Profile shape for Simple/FenceGate/Sliding is shared only because all three are actually single-entity N/W definitions:

```text
Services/Moveables/SingleEntityDoorProfiles.lua
```

Paired remains a separate profile provider because its left/right entity geometry is structurally different.

## Placement ownership

`DoorPlacement.canPlaceUnframedAt()` performs the common physical safety checks:

```text
square exists
facing valid
no vehicle intersection
no door already occupies the orientation
```

It simply does not add a frame requirement.

`SingleTileDoorPlacement` selects this rule for `FenceGate` and `Sliding`.

## Engine scripts

```text
media/scripts/SmallWhiteWoodenGate.txt
media/scripts/BrownSlidingGlassDoor.txt
```

Each contains:

```text
one transport moveable item
one XUI entry
one CraftRecipe
one SpriteConfig
```

No per-door inventory appearance work is being done here. Package/flatpack appearance remains explicitly deferred until Garage and LargeGate behavior is implemented.

## VALIDÉ EN JEU — 2026-09-05

The user exercised the two pilots in the same cold-start checkpoint as White Panel and Blue Church Paired and reported all four functional.

Validated pilot mechanics:

```text
Small White Wooden Gate
-> Build without frame
-> Pickup
-> replace without frame
-> N/W path functional
-> HP/max-HP transport functional
-> final LMION path functional

Brown Sliding Glass Door
-> Build without frame
-> MetalWelding Moveables tool bridge functional
-> Pickup / replacement functional
-> N/W path functional
-> HP/max-HP transport functional
-> final LMION path functional
```

This validates these two pilot definitions and the shared unframed 1x1 architecture. It does **not** automatically validate every FenceGate or Sliding definition, nor does it freeze the remaining polish/details for release.