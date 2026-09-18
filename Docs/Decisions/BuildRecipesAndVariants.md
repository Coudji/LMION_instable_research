# Definition-owned Build recipes and variants

Status: active V3 decision.

## Source of truth

LMION definitions are the source of truth for construction data that LMION owns.

For a migrated LMION buildable entity, the effective definition owns:

```text
construction.category
construction.skill
construction.time
construction.xp
construction.tools
construction.materials
construction.variantGroup
```

The PZ entity script keeps the `CraftRecipe` component shell required for Project Zomboid to create the buildable recipe object, but it does not duplicate the recipe values above.

At bootstrap, `Runtime/Build/CraftRecipeHydrator.lua` translates the effective definition into the PZ `CraftRecipe` contract and reloads that existing recipe object. `PZ/BuildRecipe.lua` is the narrow engine adapter used for recipe lookup.

This keeps one gameplay source of truth while preserving the parse-time GameEntity structure expected by PZ.

The migration is deliberate and explicit. `Bootstrap/Build.lua` currently enumerates the definitions whose static recipes have been replaced by definition-owned hydration. Do not infer support by scanning directories or automatically hydrate every definition merely because it has a `construction` table.

## Vanilla-facing categories

Construction category is definition data, not an LMION branding category.

An opening that naturally belongs with vanilla woodworking, welding or another construction family should use the corresponding PZ category. LMION making an existing-style opening buildable or moveable is not by itself a reason to place that opening under an `LMION` category.

## Variant groups

`construction.variantGroup` is a **catalog presentation contract**.

Definitions sharing the same non-empty variant group are represented by one visible recipe in the construction list. The right side of the Build window exposes the members as selectable models.

A variant group does **not** mean that its members have identical recipes.

Each member remains a real PZ build recipe backed by its own effective LMION definition. Switching variant calls PZ `BuildLogic:setRecipe()` with that member's real recipe, allowing vanilla to refresh the complete detail panel:

```text
name
icon
skill requirements
materials/tools
availability/build control
selected build object
```

This deliberately allows variants to differ in materials, skill, time or other recipe data. For example, colored variants may require different paint items while still sharing one catalog entry.

`variantGroup = false` is an explicit opt-out from an inherited variant group. It is a presentation decision, not a statement that the recipe is technically incompatible with grouping.

## Representative member

The representative is the first registered definition in a variant group.

Built-in registration is explicit through `Definitions/BuiltinContent.lua`, so the representative is reviewable and deterministic. For the current metal service-door group, `Doors.Metal.BlackServiceDoor` is registered first and is therefore the visible catalog representative.

Do not add a second duplicate list solely to choose the representative while registration order already expresses that decision clearly.

## Hidden variants and sequential Build

Non-representative recipes remain real recipes but are filtered out of the visible construction list through PZ's `OnAddToMenu` callback.

Because the active recipe may therefore be absent from the visible list, `client/LMION/Hooks/Build/Variants.lua` preserves the selected variant across vanilla's post-build refresh before vanilla resumes sequential placement.

The hook does not replace the selected build entity. Once the actual variant recipe is active, vanilla already creates the correct ghost and final entity, so LMION delegates that behavior back to PZ.

## Ownership

```text
Bootstrap/Build.lua
    Build startup coordination and explicit recipe-hydration migration list

Runtime/Build/CraftRecipeHydrator.lua
    effective definition -> PZ CraftRecipe translation

Runtime/Build/VariantMenuFilter.lua
    PZ OnAddToMenu callback boundary

Services/Build/VariantGroups.lua
    semantic group membership and representative selection

Services/Build/VariantState.lua
    active BuildLogic variant selection

PZ/BuildRecipe.lua
    narrow ScriptManager/build-recipe lookup adapter

client/LMION/UI/Build/VariantSelector.lua
    selector widget/presentation

client/LMION/Hooks/Build/Variants.lua
    narrow vanilla UI integration and sequential-build restoration
```

`Services/Build` does not own PZ UI objects or direct ScriptManager lookup. The client hook does not own grouping policy or recipe construction.
