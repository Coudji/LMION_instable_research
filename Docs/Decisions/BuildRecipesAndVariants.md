# Definition-owned Build recipes and variants

Status: active V3 decision.

## Source of truth

LMION definitions are the source of truth for construction data that LMION owns.

For a migrated LMION buildable entity, the effective definition owns:

```text
construction.category
construction.timedAction
construction.skill
construction.unlock
construction.time
construction.xp
construction.tools
construction.materials
construction.variantGroup
```

The PZ entity script keeps the `CraftRecipe` component shell required for Project Zomboid to create the buildable recipe object, but it does not duplicate the recipe values above.

At runtime, Build translates the effective definition into the PZ `CraftRecipe` contract and reloads that existing recipe object. `PZ/BuildRecipe.lua` is the narrow engine adapter used for exact GameEntity/CraftRecipe lookup.

The generic translation lives in `Runtime/Build/CraftRecipeHydrator.lua`. Families whose PZ recipe shape is materially different keep their translation with that family. Garage uses `Runtime/Build/Garage/CraftRecipeHydrator.lua` because its variable-width input and width-dependent material presentation are part of the Garage Build contract rather than a generic recipe rule.

This keeps one gameplay source of truth while preserving the parse-time GameEntity structure expected by PZ.

## Recipe discovery and lifecycle

`Bootstrap/Build.lua` does not keep a second list of definition-owned recipes. It iterates registered definitions, resolves their effective data, derives their build GameEntity ids and hydrates every matching definition-owned CraftRecipe. The definition registry is the ownership boundary; script-authored recipe bodies are not a second gameplay source of truth.

LargeGate is the family-specific exception to direct entity projection: one definition describes the complete A+B gate while PZ exposes one CraftRecipe per leaf. `Runtime/Build/LargeGate/CraftRecipeHydrator.lua` projects the complete definition into equal A/B leaf recipes, including category, unlock/menu callback, half time/XP and half materials.

The registry exposes a revision/change boundary. Build refreshes its projections when definitions/defaults/extensions are registered after initial bootstrap and retries at `OnGameBoot`. A third-party addon therefore does not need a second recipe-registration API or an LMION-specific CraftRecipe ModID.

The old `LMION_DEV` recipe ModID gate is intentionally gone. Registration in the LMION definition registry, plus a matching GameEntity/CraftRecipe shell, is the ownership signal.

## Construction action

`construction.timedAction` is authored data. Build does not infer it from a skill name.

For example:

```lua
construction = {
    timedAction = "BuildWallHammer",
    skill = { Woodwork = 6 },
    ...
}
```

or:

```lua
construction = {
    timedAction = "BuildWallMetal",
    skill = { MetalWelding = 4 },
    ...
}
```

An addon may provide another valid PZ timed-action id without requiring a core mapping.

The generic Build hydrator serializes the authored skill table rather than maintaining a Woodwork/MetalWelding whitelist. Numeric `construction.xp` remains convenient for a single-skill recipe; a skill table can be used when a PZ recipe legitimately has several skill XP awards.

## Construction input descriptors

`construction.tools` is definition data. The Build translator must not contain a whitelist that maps known tool ids to hand-authored recipe strings.

A tool descriptor may select its input with one of:

```lua
{ tag = "base:screwdriver" }
{ anyTagOf = { "base:hammer", "SomeMod:hammer" } }
{ item = "Base.Screwdriver" }
{ anyOf = { "Base.ToolA", "SomeMod.ToolB" } }
```

Tool identity is therefore open-ended: an addon may use a new item or tag without requiring an LMION core change. Tools default to `amount = 1` and `mode = "keep"`; either can be stated explicitly when a recipe needs something else.

PZ input flags that are part of the authored recipe also live on the descriptor rather than in a hidden tag-specific lookup. For example a woodworking hammer contract may state:

```lua
tools = {
    {
        tag = "base:hammer",
        flags = { "Prop1", "MayDegradeVeryLight" },
    },
    { tag = "base:screwdriver" },
}
```

`Runtime/Build/CraftRecipeInputs.lua` owns the mechanical conversion of those descriptors to PZ input syntax. It is shared by the generic recipe hydrator and family-specific hydrators.

`construction.materials` uses the same selector vocabulary (`tag`, `anyTagOf`, `item`, `anyOf`). Normal recipes define a numeric `amount` or `uses`; `uses` is translated to PZ's non-recorded-input form used by drainable construction consumables. Optional `mode` and `flags` remain explicit definition data.

## Garage width-dependent materials

Garage runtime knows that a Garage has a variable **width**. It does not know that a Garage is made from `SmallSheetMetal`, `MetalBar`, `GlassPanel`, or any other concrete resource.

Width scaling lives on Garage material descriptors, for example:

```lua
materials = {
    {
        item = "Base.SmallSheetMetal",
        amount = { perWidth = 3 },
    },
    {
        anyOf = { "Base.MetalBar", "Base.IronBar" },
        amount = { perWidth = 1 },
        widthInput = true,
    },
    {
        item = "Base.WeldingRods",
        uses = { perStep = 2, step = 3, max = 20 },
    },
}
```

`Services/Build/Garage/Materials.lua` evaluates that authored contract for a selected width. `widthInput = true` identifies the one PZ variable input used to drive Garage width; `WidthState` and finalization discover that input from the definition rather than searching for MetalBar/IronBar by name.

`Services/Build/Garage/Requirements.lua` derives stock checks and extra consumption from the same evaluated material descriptors. There is no second solid/glazed resource table and no Glass-material heuristic.

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

This deliberately allows variants to differ in materials, skill, time or other recipe data.

`variantGroup = false` is an explicit opt-out from an inherited variant group. It is a presentation decision, not a statement that the recipe is technically incompatible with grouping.

No group-specific registration list exists. Variant membership is derived entirely from the effective registered definitions.

Multipart definitions use the same logical `variantGroup` without inventing per-side ids. Build derives the structural role from the definition itself: Paired members become `left`/`right`, and LargeGate members become `A`/`B`. Members only group with variants sharing both the logical group id and the structural role. Addons therefore join the correct side automatically.

Variant order is also derived. Members are sorted first by progression level, then by constructed durability at that level, then by a deterministic name fallback. There is no authored `variantOrder` field. Third-party definitions therefore join a group naturally without knowing built-in ordering values.

## Unlocks and representative member

`construction.unlock` may explicitly define a skill threshold. When it is absent, Build derives the visibility threshold from `construction.skill`. Recipes are therefore added to the construction catalog only when their construction progression has been reached, while an explicit unlock can later represent a different progression contract.

For a variant group, the visible representative is the first currently unlocked member in the derived group order. Locked members are omitted from the selector; newly unlocked members are added without removing earlier models.

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

## Hidden variants and sequential Build

Non-representative recipes remain real recipes but are filtered out of the visible construction list through PZ's `OnAddToMenu` callback.

Because an active variant may be absent from the visible list, and Garage also carries a selected width across repeated placement, `client/LMION/Hooks/Build/RepeatPlacement.lua` is the single owner of the `ISBuildPanel.onStopCraft` extension point. It snapshots the independent variant and Garage states, lets vanilla perform its normal refresh, then restores whichever states applied.

Once the actual variant recipe is restored, vanilla creates the correct ghost and final entity. LMION does not replace the build entity merely to implement variant selection.

## Ownership

```text
Bootstrap/Build.lua
    Build startup/registry-refresh coordination and recipe-shell discovery

PZ/BuildRecipe.lua
    exact GameEntity -> CraftRecipe engine lookup

Runtime/Build/CraftRecipeInputs.lua
    generic definition input descriptor -> PZ CraftRecipe input syntax

Runtime/Build/CraftRecipeHydrator.lua
    generic effective definition -> PZ CraftRecipe translation

Services/Build/Garage/Materials.lua
    Garage definition material scaling evaluation

Runtime/Build/Garage/CraftRecipeHydrator.lua
    Garage-specific variable-width PZ recipe translation

Runtime/Build/MenuFilter.lua
    shared PZ OnAddToMenu boundary for unlocks and variants

Services/Build/VariantGroups.lua
    semantic group membership and representative selection

Services/Build/VariantState.lua
    active BuildLogic variant selection

client/LMION/Hooks/Build/RecipeOptions.lua
    single vanilla Build recipe options UI boundary

client/LMION/Hooks/Build/RepeatPlacement.lua
    single post-build repeat-placement state restoration boundary
```

Build does not own tool/material identity outside definitions. Client hooks do not own grouping policy or recipe construction.
