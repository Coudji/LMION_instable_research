# LargeGate Build A/B

Status: HYPOTHÈSE / NON VALIDÉ EN JEU.

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

LMION intervenes only to expose the A/B engine topology and to enforce the final LMION object/durability contract.

## Engine bridge

The three vanilla entities below initially own both leaves in one four-tile SpriteConfig:

- `Base.DoubleDoor`
- `Base.DoubleWireGate`
- `Base.DoubleFenceGate`

At `OnGameBoot`, `Runtime/Build/VanillaLargeGateLeafPreparation.lua` first verifies their exact vanilla closed-tile set, then narrows that SpriteConfig to leaf A. Leaf B is supplied by an explicit `...B` GameEntity.

The other LargeGate definitions use explicit `...A` and `...B` GameEntities directly.

This is the same control point used by the validated Legacy architecture. The V3 implementation deliberately refuses the rewrite if the expected vanilla SpriteConfig no longer matches.

After that topology preparation, `Runtime/Build/DoorScriptProjection.lua` projects the effective LMION door definition back into the PZ GameEntity scripts for engine properties that vanilla Build still consumes directly. Frame policy is the first such projection:

```text
doorType -> DoorTypes.frameRequirement -> SpriteConfig.dontNeedFrame
```

For LargeGate, both derived leaf entities A and B receive `dontNeedFrame = true` because `LargeGate -> frameRequirement = none`.

## Static script policy

There is one `media/scripts/*.txt` file per LargeGate definition. These files contain only engine-facing Build data that still has to exist statically:

- A/B XUI presentation;
- the two-tile closed SpriteConfig required by vanilla Build;
- CraftRecipe fields required by PZ's script-time recipe parser.

`dontNeedFrame` is intentionally absent from the static scripts. The Lua definition remains authoritative and the value is projected at `OnGameBoot`.

Durability values are not duplicated in SpriteConfig. V3 definitions remain authoritative for construction health.

The recipe for one leaf is half of the definition's full LargeGate construction cost/time/XP. A and B use the same leaf recipe.

## Post-build hook

`Hooks/Build/LargeGate.lua` owns only LargeGate post-build finalization at `ISBuildIsoEntity.setInfo`.

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

The hook does not replace vanilla placement or resource consumption.

## Lifecycle

`media/scripts` is parsed before Lua. At `OnGameBoot`:

1. the three vanilla base LargeGate SpriteConfigs are narrowed to leaf A;
2. LMION resolves the registered effective definitions;
3. frame requirements are projected into each managed GameEntity `SpriteConfig` without `PreReload()`, so existing faces and tiles remain untouched;
4. Build diagnostics run against the resulting engine state.

Because this checkpoint changes `OnGameBoot` GameEntity state, runtime validation requires a cold game restart.

## Evidence

- A/B topology and recipes: `OBSERVÉ DANS LEGACY / SOURCE`.
- `GameEntityScript:Load` component reload behavior: `OBSERVÉ DANS PZ 42.20.3 JAR`.
- `SpriteConfigScript.dontNeedFrame` parsing/getter: `OBSERVÉ DANS PZ 42.20.3 JAR`.
- V3 definition-owned frame projection: `IMPLÉMENTÉ / À VALIDER EN JEU`.
