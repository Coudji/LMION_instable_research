# Definition authority audit

Status: active V3 architecture checkpoint, 2026-09-18.

## Rule

An effective LMION definition owns content facts. Runtime code may own Project Zomboid integration details and true family invariants, but it must not maintain a second content catalog.

The practical test is:

```text
Would changing this value for one third-party definition require editing LMION core?

Yes -> content knowledge is still leaking into runtime.
No  -> the definition/API boundary is doing its job.
```

## Build

Resolved in the current refactor:

- no tool-name whitelist in CraftRecipe hydration;
- `construction.timedAction` is explicit definition data rather than inferred from Woodwork/MetalWelding;
- generic Build skill/XP serialization is not restricted to those two skill names;
- exact CraftRecipe lookup starts from the registered GameEntity rather than recipe short-name identity;
- the SingleTile Build hook no longer requires CraftRecipe ModID `LMION_DEV`;
- Build recipe discovery understands both `entity` and multipart `entities` definitions;
- registry changes can refresh definition-owned recipe projections after initial LMION bootstrap;
- recipe variant membership remains derived from effective definitions and registry order.

The empty `CraftRecipe` shell check remains an intentional migration boundary. It distinguishes definition-owned recipes from recipes that have not yet been migrated out of static PZ scripts. It is not intended to be the final ownership marker after migration is complete.

## Garage Build

Resolved in the current refactor:

- concrete Garage resource ids are no longer duplicated in `Garage/Requirements.lua`;
- Solid/Glazed are no longer selected by inspecting `engineMaterials` for Glass;
- width formulas are authored on `construction.materials` descriptors;
- the PZ variable input is declared with `widthInput = true` instead of being detected as MetalBar/IronBar;
- stock checking, UI amounts, CraftRecipe projection and extra consumption derive from the same effective-definition material descriptors;
- finalization determines the amount already consumed by vanilla from the declared width-input alternatives rather than concrete bar item ids.

Garage runtime still owns the real family invariant: a Garage has a variable width and PZ represents that width through one variable CraftRecipe input.

## Moveables

Resolved in the current refactor:

- removed the screwdriver/crowbar/hammer gameplay whitelist;
- removed the three fixed `LMIONMetal*` tool definitions;
- arbitrary item/tag selectors are expanded into PZ Moveables tool definitions;
- pickup/replacement action time, sound and optional animation come from the effective definition;
- replacement may define its own governing skill; otherwise it explicitly inherits pickup skill as a schema default;
- package item identity is definition-owned through `packages.item` or `packages.itemTemplate`;
- runtime no longer constructs transport item ids from `Base.LMION_<entity>` conventions;
- the Paired Moveables pilot whitelist is gone; all valid registered Paired definitions use the same profile derivation;
- pickup break chance is read from `pickup.breakChance` instead of being replaced by a hidden runtime rule;
- definition-derived Moveables indexes that depend on the registry are revision-aware;
- registry changes refresh generated tool definitions and, after tile definitions are loaded, sprite projections.

Presentation is allowed to be optional. An addon does not need an LMION-known tool identity to work; it may declare its own animation/sound or omit custom presentation.

## Legitimate engine/family knowledge

The following are not content leaks:

- `DoorTypes` frame consequences for semantic door families;
- PZ native LargeGate logical indices/offsets in `LargeGateTopology`;
- Garage `START/MIDDLE/END` physical roles;
- Garage width policy and runtime SpriteGrid mechanics;
- explicit compatibility adaptation of known vanilla LargeGate GameEntities in `VanillaLargeGateLeafPreparation`;
- PZ API syntax, ComponentType access, CraftRecipe loading and Moveables tool-definition plumbing.

Those values describe the engine contract or the meaning of a supported family, not the recipe for one specific door.

## Still intentionally unresolved

### Moveables replacement materials

`replacement.materials` exists in current data but every built-in definition uses an empty list. Generic consumption semantics are not finalized, especially for multipart Garage/LargeGate replacement where it must be clear whether requirements apply per parcel, per leaf, or per complete opening.

Until that contract is decided, non-empty `replacement.materials` must not be advertised as a supported addon feature.

### Strict public-schema validation

Strict validation remains deferred until the API shape is considered complete. Current runtime services fail loudly on malformed contracts where necessary, but the final centralized validation pass should be done once rather than repeatedly while the schema is still moving.

### Exhaustive external-addon validation

The architecture now has the necessary late-registration and open-ended selector paths, but a real external addon with custom GameEntity ids, parcel ids, a custom tool/tag and custom presentation still needs an end-to-end in-game test before the public modding guide can claim that workflow as validated.

## Regression stance

This refactor changes several previously validated projection boundaries at once. Static inspection can catch ownership mistakes, but it cannot prove Project Zomboid lifecycle behavior. The next runtime checkpoint should prioritize:

```text
cold startup
Simple pickup/place presentation
wood FenceGate crowbar/hammer presentation
Garage Build width/resources at several widths
Garage pickup/place
Paired pickup/place
migrated Build variants and sequential placement
```

Only after that checkpoint should recipe migration resume.
