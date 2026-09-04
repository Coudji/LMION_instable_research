# V3 foundation files

This note explains the first active V3 Lua foundation. The goal is to keep each file responsible for one clear thing and make the source tree easy to navigate.

## `LMION/Support/TableUtils.lua`

Responsibility: generic table mechanics only.

It currently provides:

- `deepCopy()` so Registry inputs/outputs cannot accidentally share mutable table state;
- `deepMerge()` for DefinitionDefault inheritance and extension patches.

It knows nothing about doors, Project Zomboid, Build, Pickup or the public API.

## `LMION/Domain/DoorTypes.lua`

Responsibility: define the finite semantic door-type vocabulary and the internal characteristics directly implied by each type.

Current types:

```text
Simple
Paired
FenceGate
Sliding
LargeGate
Garage
```

It currently derives one internal characteristic: frame requirement.

Definitions expose `doorType`; they do not need a separate public `frame` field merely to repeat a consequence of the type.

## `LMION/Definitions/Registry.lua`

Responsibility: raw storage of registered content.

It stores:

- DefinitionDefaults by `defaultId`;
- concrete Definitions by `definitionId`;
- Extensions in registration order.

Duplicate identities are errors. Values are copied on registration.

Registry is internal implementation state, not the modder-facing API.

## `LMION/Definitions/Validation.lua`

Responsibility: reject structurally invalid public data before Registry stores it.

It validates identity fields, inheritance shape, extension targets and supported `doorType` values.

It deliberately does not validate runtime geometry against PZ yet; that belongs to later engine-facing validation work.

## `LMION/Definitions/Resolver.lua`

Responsibility: produce effective data from raw registered data.

Resolution order is:

```text
DefinitionDefault
-> extensions targeting that default
-> concrete Definition overrides
-> extensions targeting that definition
```

It does not know anything about placement, pickup or construction.

## `LMION/API.lua`

Responsibility: stable public facade for LMION and third-party addons.

External code should use:

```lua
local LMION = require "LMION/API"
```

The API delegates storage, validation and resolution to the internal modules. It must stay smaller and more stable than the internals.

The first public API version is `1`.

## `LMION/Definitions/Defaults/...`

Responsibility: pure reusable data defaults.

These files return tables only. They do not register themselves and have no side effects.

The first migrated example is `WoodFourPanels.lua`.

## `LMION/Definitions/Catalog/...`

Responsibility: pure data for one exact supported opening.

The first migrated example is `WhitePanelDoor.lua`, including explicit N/W closed/open geometry.

## `LMION/Definitions/BuiltinContent.lua`

Responsibility: explicitly list the built-in data shipped by LMION.

LMION intentionally does not scan folders to discover definitions. Explicit registration keeps startup deterministic and gives built-in content the same registration path as third-party content.

## `LMION/Bootstrap/Definitions.lua`

Responsibility: register built-in definitions exactly once through the public API.

It does not contain the catalog itself and does not perform gameplay/runtime hooks.

## `LMION_DEV.lua`

Responsibility: tiny mod bootstrap entrypoint.

It loads the public API, runs the definition bootstrap, then prints one compact registration summary.

No gameplay hook, cursor, construction behavior or world-object mutation belongs here.

## Current boundary

This checkpoint is intentionally data-only.

There is no Pickup runtime, Build hook, Moveables hook, IsoDoor conversion or LargeGate mutation in this foundation yet. Those will be added later in their own responsibility areas after the corresponding research is read and the vanilla boundary is explicit.
