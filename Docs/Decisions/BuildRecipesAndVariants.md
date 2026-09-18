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

At bootstrap, Build translates the effective definition into the PZ `CraftRecipe` contract and reloads that existing recipe object. `PZ/BuildRecipe.lua` is the narrow engine adapter used for recipe lookup.

The generic translation lives in `Runtime/Build/CraftRecipeHydrator.lua`. Families whose PZ recipe shape is materially different keep their translation with that family. Garage uses `Runtime/Build/Garage/CraftRecipeHydrator.lua` because its variable-width bar input and width-dependent material presentation are part of the Garage Build contract rather than a generic recipe rule.

This keeps one gameplay source of truth while preserving the parse-time GameEntity structure expected by PZ.

`Bootstrap/Build.lua` does not keep a second list of definition-owned recipes. It iterates the registered definitions, resolves their effective data, and hydrates a recipe when all of the following are true:

```text
the effective definition has construction data
the definition exposes one entity id
a PZ buildable recipe exists for that entity
the existing CraftRecipe is an empty shell
```

The empty-shell check is the migration boundary. It lets LMION discover definition-owned recipes from registered data without overwriting build recipes that are still explicitly authored in PZ scripts.

This also applies to definitions registered by third-party addons before Build bootstrap runs. A modder does not register a variant or recipe in a separate LMION list: registering the definition and supplying the corresponding empty `CraftRecipe` shell is sufficient.

## Vanilla-facing categories

Construction category is definition data, not an LMION branding category.

An opening that naturally belongs with vanilla woodworking, welding or another construction family should use the corresponding PZ category. LMION making an existing-style opening buildable or moveable is not by itself a reason to place that opening under an `LMION` category.

Current migrated examples include:

```text
Doors.Wood.FourPanels -> Carpentry
Doors.Metal.Service   -> Welding
GarageDoors.Solid     -> Welding
```

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

No group-specific registration list exists. Variant membership is derived entirely from the effective registered definitions.

## Representative member

The representative is the first registered definition in a variant group.

Built-in registration is explicit through `Definitions/BuiltinContent.lua`, so the representative is reviewable and deterministic. For the current metal service-door group, `Doors.Metal.BlackServiceDoor` is registered first and is therefore the visible catalog representative.

Third-party definitions participate through the same registry and grouping mechanism. A mod that wants several of its definitions grouped gives them the same `construction.variantGroup` value; it does not call a second variant-registration API.

## Build recipe options UI

Variant selection and family-specific controls may coexist for one recipe. A grouped Garage, for example, needs both a model selector and the Garage width selector.

`client/LMION/Hooks/Build/RecipeOptions.lua` is therefore the single owner of the `ISBuildRecipePanel.createDynamicChildren` extension point. It injects one `RecipeOptionsPanel` into the vanilla filler row. The panel composes the controls that apply to the current recipe instead of letting multiple subsystem hooks replace the same table cell.

The individual widgets remain independent:

```text
UI/Build/VariantSelector.lua
    model selection only

UI/Build/GarageWidthSelector.lua
    Garage width selection only

UI/Build/RecipeOptionsPanel.lua
    presentation composition only
```

Garage and variant business rules remain in their own services. The shared client boundary exists only because PZ exposes one UI location for those independent controls.

## Hidden variants and sequential Build

Non-representative recipes remain real recipes but are filtered out of the visible construction list through PZ's `OnAddToMenu` callback.

Because an active variant may be absent from the visible list, and Garage also carries a selected width across repeated placement, `client/LMION/Hooks/Build/RepeatPlacement.lua` is the single owner of the `ISBuildPanel.onStopCraft` extension point. It snapshots the independent variant and Garage states, lets vanilla perform its normal refresh, then restores whichever states applied.

Once the actual variant recipe is restored, vanilla creates the correct ghost and final entity. LMION does not replace the build entity merely to implement variant selection.

## Ownership

```text
Bootstrap/Build.lua
    Build startup coordination and discovery of definition-owned recipe shells

Runtime/Build/CraftRecipeHydrator.lua
    generic effective definition -> PZ CraftRecipe translation

Runtime/Build/Garage/CraftRecipeHydrator.lua
    Garage-specific variable-width PZ recipe translation

Runtime/Build/VariantMenuFilter.lua
    PZ OnAddToMenu callback boundary

Services/Build/VariantGroups.lua
    semantic group membership and representative selection

Services/Build/VariantState.lua
    active BuildLogic variant selection

PZ/BuildRecipe.lua
    narrow ScriptManager/build-recipe lookup and shell inspection adapter

client/LMION/UI/Build/RecipeOptionsPanel.lua
    compose applicable Build recipe controls

client/LMION/UI/Build/VariantSelector.lua
    variant selector widget/presentation

client/LMION/UI/Build/GarageWidthSelector.lua
    Garage width selector widget/presentation

client/LMION/Hooks/Build/RecipeOptions.lua
    single vanilla Build recipe options UI boundary

client/LMION/Hooks/Build/RepeatPlacement.lua
    single post-build repeat-placement state restoration boundary

client/LMION/Hooks/Build/Variants.lua
    loads the variant-related Build adapters; no recipe/UI business logic
```

`Services/Build` does not own PZ UI objects or direct ScriptManager lookup. Client hooks do not own grouping policy or recipe construction.
