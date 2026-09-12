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

There is one `media/scripts/*.txt` file per LargeGate definition. These files contain engine-facing Build data:

- A/B XUI presentation;
- the two-tile closed SpriteConfig required by vanilla Build;
- CraftRecipe fields required by PZ's script-time recipe parser.

Durability values are not duplicated in SpriteConfig. V3 definitions remain authoritative for construction health.

The recipe for one leaf is half of the definition's full LargeGate construction cost/time/XP. A and B use the same leaf recipe.

### Known frame-policy gap

LMION definitions are intended to remain authoritative for frame semantics:

```text
Simple    -> standard
Paired    -> paired
FenceGate -> none
Sliding   -> none
LargeGate -> none
Garage    -> none
```

After `dontNeedFrame` was removed from the static LMION SpriteConfigs, no-frame Build entities became invalid unless placed in a door frame. The three vanilla LargeGate A entities continued to work only while their runtime split rewrite still contained `dontNeedFrame = true`.

An experiment attempted to project only `dontNeedFrame` into already-loaded GameEntity scripts at `OnGameBoot` by calling `GameEntityScript:Load()` with a minimal `SpriteConfig` fragment. In-game testing failed: Garage, Sliding/FenceGate and both LargeGate leaves still behaved as frame-required, while removing the hardcoded property from the vanilla A rewrite also broke A.

Inspection of the PZ 42.20.3 bytecode explains why that minimal fragment did not work. `SpriteConfigScript.load()` processes component scalar values such as `dontNeedFrame` from inside its child-block loop. A component fragment containing only:

```text
component SpriteConfig
{
    dontNeedFrame = true,
}
```

has no child block, so the scalar value is never applied. The experiment has been reverted and must not be repeated in that form.

The remaining architectural choice is therefore between a narrow Build-time bridge that derives `ISBuildIsoEntity.dontNeedFrame` from the effective LMION definition, or a broader full SpriteConfig regeneration/projection that includes geometry. No replacement has been selected yet.

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
- `SpriteConfigScript.dontNeedFrame` parser/getter: `OBSERVÉ DANS PZ 42.20.3 JAR`.
- minimal late `dontNeedFrame` projection without child blocks: `ÉCHEC VALIDÉ EN JEU`, explained by bytecode inspection.
- V3 LargeGate Build behavior after frame metadata cleanup: known regression pending a replacement frame bridge.
