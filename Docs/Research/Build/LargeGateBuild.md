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

## Static script policy

There is one `media/scripts/*.txt` file per LargeGate definition. These files contain only engine-facing Build data:

- A/B XUI presentation;
- the two-tile closed SpriteConfig required by vanilla Build;
- `dontNeedFrame = true`;
- CraftRecipe fields required by PZ's script-time recipe parser.

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

`media/scripts` is parsed before Lua. The three vanilla base SpriteConfigs are narrowed at `OnGameBoot`, before loaded tile definitions configure runtime moveable metadata.

Because this checkpoint changes both `media/scripts` and `OnGameBoot` GameEntity topology, runtime validation requires a cold game restart.

## Evidence

- A/B topology and recipes: `OBSERVÉ DANS LEGACY / SOURCE`.
- `GameEntityScript:Load` component reload behavior: `OBSERVÉ DANS PZ 42.20.3 JAR`.
- V3 LargeGate Build behavior: `HYPOTHÈSE / NON VALIDÉ` until the integrated game checkpoint.
