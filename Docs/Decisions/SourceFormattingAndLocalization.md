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

## Script metadata ownership

PZ script files contain only parse-time facts that the engine actually needs.

Do not add `dontNeedFrame` or `BreakSound` to `component SpriteConfig`.

In V3:

- frame requirements are semantic consequences of the Lua definition / `doorType` model;
- material and sound behavior belong to the definition/runtime material model;
- unsupported or redundant script properties must not be duplicated merely as documentation.

If a future Project Zomboid version introduces a supported script property that LMION genuinely needs, verify it against current vanilla scripts/API before adding it.

## Localization

Every newly declared user-visible or inventory-visible LMION item must receive translation keys at the same time it is introduced.

The maintained baseline languages are:

```text
EN
FR
```

This includes:

- `ItemName.json` for moveable/transport items;
- `IG_UI.json` for LMION UI labels and keybind descriptions;
- `Sandbox.json` for LMION Sandbox settings;
- `Mod.json` for translated `mod.info` name/description metadata.

Technical parcel items are still inventory-visible and therefore require localized names. Internal identifiers remain stable English/code identifiers; only display text is localized.
