# Source formatting and localization rules

Status: active V3 project rule.

LMION source files are maintained for humans first. Compact/minified source is not accepted in the repository even when it is syntactically valid.

## Formatting

PZ script files and Lua files must use normal multiline formatting:

- one identifiable property or statement per line;
- explicit indentation for nested blocks;
- avoid chaining unrelated statements with semicolons;
- avoid one-line functions except for genuinely trivial expressions;
- split complex conditions and function calls across lines when it improves readability;
- preserve existing behavior when a change is only a formatting pass.

Generated-looking compact source such as this is not acceptable:

```text
item Example { ItemType=base:moveable, Icon=Flatpack, Weight=20.0, }
```

Use normal block formatting instead.

## Script directory organization

Project Zomboid recursively loads `.txt` files below `media/scripts`, so LMION keeps engine-facing script declarations grouped by opening family instead of leaving every file at the root.

Current layout:

```text
media/scripts/
├─ Doors/
│  ├─ Single/
│  └─ Paired/
├─ FenceGates/
├─ SlidingDoors/
│  └─ Single/
├─ LargeGates/
└─ GarageDoors/
```

Keep this hierarchy intentionally shallow. Do not mirror material categories such as Wooden/Metal in `media/scripts` unless a future engine-facing distinction genuinely requires it.

`SlidingDoors/Single` is intentionally one level deeper so future structural variants such as `SlidingDoors/Paired` or `SlidingDoors/Double` can be added without reorganizing the existing single sliding-door scripts.

Moving a script file between these directories does not change its PZ module/entity/item identifiers. File paths are repository organization only; declarations such as `Base.DoubleDoor` remain unchanged.

## Script metadata ownership

PZ script files contain only parse-time facts that the engine actually needs.

Frame requirements remain semantic consequences of the effective Lua definition / `doorType` model. Do not treat `dontNeedFrame` as public definition data and do not require external LMION definitions to duplicate that PZ implementation detail.

The active V3 Build policy is now definition-owned:

```text
effective LMION definition
-> doorType
-> DoorTypes frame requirement
-> ISBuildIsoEntity.dontNeedFrame
```

`Hooks/Build/DoorFrameRequirement.lua` applies that consequence after vanilla creates the `ISBuildIsoEntity` object. This keeps the public definition semantic while still supplying the boolean expected by vanilla Build validation.

In-game validation confirmed the intended distinction after static `dontNeedFrame` metadata was removed from LMION scripts:

```text
Simple / Paired -> frame still required
FenceGate / Sliding / LargeGate / Garage -> no frame required
```

A previous experiment attempted to project only `dontNeedFrame` into already-loaded `GameEntityScript` / `SpriteConfig` objects with a minimal `GameEntityScript:Load()` fragment. That approach failed in game and was reverted. Do not reintroduce that projection. The investigation is recorded in `Docs/Research/Build/LargeGateBuild.md`.

The three vanilla LargeGate A entities are still narrowed by `Runtime/Build/VanillaLargeGateLeafPreparation.lua`; that engine-topology rewrite is a separate concern from the generic frame policy. Its historical `dontNeedFrame` assignment is redundant with the validated Build hook and should not be used as the architectural source of truth.

`BreakSound` must not be added merely as redundant documentation. It is a real PZ `SpriteConfig` property, but LMION should keep it only where an engine-facing script rewrite genuinely owns or requires that value.

In V3:

- frame requirements are semantic consequences of the Lua definition / `doorType` model;
- Build translates that semantic requirement only at the narrow vanilla boundary that needs `dontNeedFrame`;
- material and sound behavior belong to the definition/runtime material model;
- supported PZ properties must not be duplicated merely as documentation when LMION does not need to own them.

If a future Project Zomboid version changes a script property or Build boundary that LMION relies on, verify it against current vanilla scripts/API/JAR before changing the integration.

## Localization

Every newly declared user-visible or inventory-visible LMION item must receive translation keys at the same time it is introduced.

The maintained baseline languages are:

```text
EN
FR
```

This includes:

- `ItemName.json` for moveable/transport items;
- `Entity.json` for Construction/GameEntity display names;
- `IG_UI.json` for LMION UI labels and keybind descriptions;
- `Sandbox.json` for LMION Sandbox settings;
- `Mod.json` for translated `mod.info` name/description metadata.

Technical parcel items are still inventory-visible and therefore require localized names. Internal identifiers remain stable English/code identifiers; only display text is localized.

### Naming rules

Workshop's definition-name translations are the historical naming baseline when they already cover an opening. V3 should preserve those choices unless there is a deliberate language or clarity correction instead of inventing a fresh name during integration.

Technical identifiers that come from Project Zomboid remain recognizable. In particular, vanilla-origin names such as `DoubleDoor`, `DoubleFenceGate`, and `DoubleWireGate` are not renamed simply to make them match the display label; modders may already know those vanilla identifiers.

User-facing names follow the target language rather than word-for-word source order. Adjective and complement order should be idiomatic in EN and FR, and the same opening must keep the same base display name between `Entity.json` and `ItemName.json`.

French size wording should avoid redundant qualifiers when the noun already conveys the distinction. Use `portillon` for the smaller form and `portail` for the larger form without mechanically adding `petit` or `grand`.

Paired door display names use only `Left` / `Right` in EN and `Gauche` / `Droite` in FR. Do not add `Leaf` or `Vantail` to inventory or construction names.

LargeGate sides remain `A` / `B` because their apparent left/right position changes with orientation.

LargeGate transport parcels use the compact suffixes `Part 1` and `Part 2` in both EN and FR. Garage transport parcels keep their semantic `Start` / `Middle` / `End` and `Début` / `Milieu` / `Fin` suffixes.
