# Definition-owned Moveables actions

Status: active V3 decision.

## Principle

Pickup and replacement behavior is authored by the effective LMION definition. Runtime adapters may translate that contract to Project Zomboid, but they must not infer gameplay requirements from a known tool name, material family or definition id.

A Moveables mode is represented by its semantic contract:

```lua
pickup = {
    skill = { Woodwork = 2 },
    tools = {
        { tag = "MyMod:powerdrill" },
    },
    action = {
        time = 80,
        sound = "MyModDrillDoor",
        soundIsWav = true,
        animation = "MyMod_DrillDoor",
    },
    breakChance = 0,
    packages = {
        count = 1,
        weight = 15,
        item = "MyMod.ExampleDoorParcel",
    },
}

replacement = {
    skill = { Woodwork = 2 },
    tools = {
        { tag = "MyMod:powerdrill" },
    },
    action = {
        time = 70,
        sound = "MyModDrillDoor",
        soundIsWav = true,
        animation = "MyMod_DrillDoor",
    },
    materials = {},
}
```

`replacement.skill` is optional. When absent, replacement inherits the pickup skill contract. This is a schema default and may be overridden explicitly.

## Tool selectors

Moveables uses the same open-ended selector vocabulary as Build:

```lua
{ item = "Base.Screwdriver" }
{ anyOf = { "Base.Hammer", "MyMod.PowerHammer" } }
{ tag = "base:crowbar" }
{ anyTagOf = { "base:crowbar", "MyMod:prytool" } }
```

One Moveables action has one tool requirement. Alternatives belong inside `anyOf` or `anyTagOf` rather than being represented as several independent required tools.

`PZ/ItemSelector.lua` resolves item/tag selectors to the concrete item types PZ's Moveables tool-definition API expects. Adding a new tool or tag therefore does not require an LMION core mapping.

`Runtime/Moveables/ToolDefinitions.lua` creates the narrow PZ tool definition for each registered definition/mode. The generated PZ name is runtime plumbing only; it is not public content identity.

## Action presentation

`action.time`, `action.sound`, `action.soundIsWav` and `action.animation` are data owned by the effective definition.

LMION does not map screwdriver/crowbar/hammer to presentation assets in runtime code. Built-in defaults explicitly declare the presentation they want.

The runtime distinction is:

```text
tool/skill/time/sound -> gameplay action contract
animation             -> optional presentation override
```

If a modder supplies a different tool, LMION does not need to recognize that tool's identity. The action remains valid as long as the selector resolves to PZ items. A custom animation is optional; when omitted LMION does not invent one from the tool name.

`client/LMION/Hooks/Moveables/ActionPresentation.lua` only owns the PZ action boundary needed to equip the already-resolved gameplay tool before presentation and optionally apply the authored animation.

## Package identity

Runtime must not manufacture a transport item id from a GameEntity name.

The pickup package contract therefore owns its item identity explicitly:

```lua
packages = {
    count = 1,
    weight = 15,
    item = "MyMod.ExampleDoorParcel",
}
```

For repetitive built-in families, an authored template may be used:

```lua
itemTemplate = "Base.LMION_{entityName}"
```

Family contexts may expose additional template values such as `{member}`, `{leaf}`, `{partIndex}`, `{role}` and `{roleIndex}`. `Services/Moveables/PackageContract.lua` performs only this declared template expansion.

An external addon is not required to follow LMION's built-in item naming convention; it can always provide its own exact `packages.item` or template.

## Break chance

`pickup.breakChance` is the authored pickup break percentage. LMION's Moveables adapter exposes that exact value to PZ instead of deriving a different chance from a hardcoded tool family.

## Lifecycle

Definitions, defaults and extensions may change the registry after LMION's initial bootstrap. Registry revision listeners refresh generated Moveables tool definitions, and once tile definitions are available they refresh sprite projections as well.

This removes the old assumption that every third-party definition must have been registered before LMION bootstrap.

## Current limits

Project Zomboid's Moveables action model has one governing perk and one tool requirement per pickup/place action. LMION keeps that engine limitation explicit instead of pretending to support several independent skills/tools in one Moveables action.

`replacement.materials` remains reserved by the definition schema but the generic Moveables material-consumption contract is not finalized yet. Built-in definitions currently use an empty replacement material list. It must not be advertised as a supported third-party feature until its semantics for multipart openings are decided and implemented.
