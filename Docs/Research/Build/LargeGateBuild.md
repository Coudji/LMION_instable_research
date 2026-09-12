# LargeGate Build A/B

Status: PARTIELLEMENT VALIDÉ EN JEU.

The LargeGate Build pipeline is implemented. The frame/no-frame integration has now been validated in game, but the complete LargeGate Build matrix (resource consumption, all families/orientations and final object state) is still not considered fully validated.

## Contract

LMION exposes LargeGate construction per leaf. A supported large gate is never built as one four-tile action:

```text
LargeGate
├─ leaf A -> physical members 1 + 2
└─ leaf B -> physical members 1 + 2
```

Each completed physical member must finish as an `IsoDoor`.

## Vanilla path kept

```text
GameEntity CraftRecipe
-> vanilla Build menu / cursor
-> SpriteConfig two-tile leaf
-> timed construction
-> ISBuildIsoEntity.setInfo for each produced tile
-> LMION post-build finalization
```

Vanilla remains responsible for the menu, ghost, facing, timed action, skills, tools/material consumption and creation of the initial world object.

LMION intervenes only where its effective definition owns behavior that vanilla cannot infer from the static script, and to enforce the final LMION object/durability contract.

## Engine topology rewrite

The three vanilla entities below initially own both leaves in one four-tile SpriteConfig:

- `Base.DoubleDoor`
- `Base.DoubleWireGate`
- `Base.DoubleFenceGate`

At `OnGameBoot`, `Runtime/Build/VanillaLargeGateLeafPreparation.lua` first verifies their exact vanilla closed-tile set, then narrows that SpriteConfig to leaf A. Leaf B is supplied by an explicit `...B` GameEntity.

The other LargeGate definitions use explicit `...A` and `...B` GameEntities directly.

This is the same control point used by the validated Legacy architecture. The V3 implementation deliberately refuses the rewrite if the expected vanilla SpriteConfig no longer matches.

This topology rewrite is a special LargeGate engine adaptation. It is not the generic mechanism by which LMION definitions become authoritative.

## Static script policy

There is one `media/scripts/*.txt` file per LargeGate definition. These files contain engine-facing Build data that PZ currently needs at script/load time:

- A/B XUI presentation;
- the two-tile closed SpriteConfig required by vanilla Build;
- CraftRecipe fields currently used by PZ's Build recipe path.

Durability and semantic frame policy are not owned by these script files. V3 definitions remain authoritative for construction health and `doorType` consequences.

The recipe for one leaf is half of the definition's full LargeGate construction cost/time/XP. A and B use the same leaf recipe.

## Frame policy — VALIDATED

LMION definitions are authoritative for frame semantics:

```text
Simple    -> standard
Paired    -> paired
FenceGate -> none
Sliding   -> none
LargeGate -> none
Garage    -> none
```

Removing `dontNeedFrame` from static LMION SpriteConfigs exposed an integration gap: vanilla Build copied `SpriteConfig.dontNeedFrame` into each `ISBuildIsoEntity`, so no-frame LMION constructions became valid only when placed in a frame.

### Failed experiment — late GameEntityScript projection

An experiment attempted to project only `dontNeedFrame` into already-loaded GameEntity scripts at `OnGameBoot` by calling `GameEntityScript:Load()` with a minimal `SpriteConfig` fragment. In-game testing failed: Garage, Sliding/FenceGate and both LargeGate leaves still behaved as frame-required, while removing the hardcoded property from the vanilla A rewrite also broke A.

Inspection of the PZ 42.20.3 bytecode explains why that minimal fragment did not work. `SpriteConfigScript.load()` processes component scalar values such as `dontNeedFrame` from inside its child-block loop. A component fragment containing only:

```text
component SpriteConfig
{
    dontNeedFrame = true,
}
```

has no child block, so the scalar value is never applied.

**FAILED APPROACH / DO NOT REINTRODUCE:** minimal late `GameEntityScript:Load()` projection of scalar-only SpriteConfig metadata.

### Active V3 integration

V3 now keeps the static scripts free from duplicated frame policy. `Hooks/Build/DoorFrameRequirement.lua` owns the narrow vanilla Build boundary:

```text
ISBuildIsoEntity.new(...)
-> vanilla object created normally
-> resolve effective LMION definition for that Build entity
-> doorType
-> DoorTypes.getFrameRequirement(...)
-> set buildObject.dontNeedFrame
```

For LargeGate A/B, the Build profile resolves the derived leaf GameEntity back to the owning LargeGate definition.

In-game validation on 2026-09-12 confirmed:

```text
White Panel / framed doors still require their proper frame
Sliding / FenceGate can build without a frame
Garage can build without a frame
LargeGate A and B can build without a frame
```

This validates the frame-policy integration only. It does not by itself validate every other LargeGate Build behavior.

Commit introducing the active hook:

```text
f8cf884e6e3dcb162a5bee797f8c6d1b76f36968  Derive Build frame requirement from LMION door type
```

## Placement permissiveness observation

With `dontNeedFrame` correctly derived, unframed constructions can currently be accepted in locations that are semantically questionable, including overlapping/aligned with existing wall/frame structures. This was observed during the frame-policy test.

This is not attributed to the `dontNeedFrame` hook itself. Existing LMION unframed placement validation is permissive and currently focuses mainly on door/vehicle conflicts. Treat stricter wall/frame/structure compatibility as a separate placement-validation task.

Do not fold that problem back into static `SpriteConfig.dontNeedFrame`; frame requirement and placement collision/compatibility are separate concerns.

## Post-build hook

`Hooks/Build/DoorSetInfo.lua` is the centralized `ISBuildIsoEntity.setInfo` owner and dispatches LargeGate finalization through `LargeGateFinalizer`.

For the tile just created:

```text
GameEntity -> LargeGate definition + A/B leaf
sprite -> facing + physical member
source door -> CanonicalDoor.ensure(... preserveLockState=false)
-> install closed/open geometry
-> construction max health from Lua definition
-> final health = max health
-> square recalc / server transmit
```

The finalizer does not replace vanilla placement or base resource consumption.

## Lifecycle

`media/scripts` is parsed before Lua. The three vanilla base SpriteConfigs are narrowed at `OnGameBoot`. Build frame policy is applied later at the narrow `ISBuildIsoEntity.new` boundary from the effective LMION definition.

Changes to script topology still require a cold restart. Pure Lua hook changes should also be tested from a clean game startup while V3 remains under active development.

## Evidence

- A/B topology and recipes: `OBSERVÉ DANS LEGACY / SOURCE`.
- `GameEntityScript:Load` component reload behavior: `OBSERVÉ DANS PZ 42.20.3 JAR`.
- `SpriteConfigScript.dontNeedFrame` parser/getter: `OBSERVÉ DANS PZ 42.20.3 JAR`.
- minimal late `dontNeedFrame` projection without child blocks: `ÉCHEC VALIDÉ EN JEU`, explained by bytecode inspection.
- definition-owned `ISBuildIsoEntity.dontNeedFrame` hook: `VALIDÉ EN JEU` for framed vs no-frame distinction across Simple/unframed single-tile/Garage/LargeGate A+B examples.
- complete LargeGate Build matrix beyond frame policy: `NON ENCORE VALIDÉE`.
