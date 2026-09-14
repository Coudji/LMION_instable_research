# V3 foundation files

This note describes the active V3 Lua foundation and its ownership boundaries. The goal is to keep each file responsible for one clear thing and make the source tree easy to navigate.

## `LMION/Support/TableUtils.lua`

Responsibility: generic table mechanics only.

It provides:

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

It derives the internal frame requirement from `doorType`.

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

Full strict public-schema validation remains deferred until the API shape is complete.

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

The current public API version is `1`.

## `LMION/Definitions/Defaults/...`

Responsibility: pure reusable data defaults.

These files return tables only. They do not register themselves and have no side effects.

## `LMION/Definitions/Catalog/...`

Responsibility: pure data for one exact supported opening.

Definitions contain addon-facing semantic/gameplay data and exact geometry. Runtime implementation consequences are derived outside the catalog where possible.

## `LMION/Definitions/BuiltinContent.lua`

Responsibility: explicitly list the built-in data shipped by LMION.

LMION intentionally does not scan folders to discover definitions. Explicit registration keeps startup deterministic and gives built-in content the same registration path as third-party content.

## `LMION/Bootstrap/Definitions.lua`

Responsibility: register built-in definitions exactly once through the public API.

It does not contain the catalog itself and does not perform gameplay/runtime hooks.

## `LMION/Bootstrap/Moveables.lua`

Responsibility: install the Moveables-facing runtime adapters once and configure runtime sprite metadata/grids at the appropriate engine event.

It coordinates hook installation but does not own family gameplay rules.

## `LMION/Services/Common/...`

Responsibility: hold knowledge that is genuinely shared by otherwise independent subsystems.

Current examples:

```text
GarageDefinitionProfiles.lua
LargeGateDefinitionProfiles.lua
LargeGateMembers.lua
SingleTileDoorPlacement.lua
```

This layer exists specifically so Build, Runtime and Moveables can share neutral opening identity/geometry/placement knowledge without depending on each other.

`Common` must not become a generic dumping ground. Moveables-only transport/tools/parcels remain under `Services/Moveables`, and Build-only construction/finalization remains under `Services/Build`.

## `LMION/Services/Build/...`

Responsibility: Build-specific services only.

Family-specific code is grouped by family:

```text
Services/Build/Garage/
Services/Build/LargeGate/
Services/Build/SingleTileDoor/
```

Cross-family construction durability remains directly under `Services/Build/ConstructionDurability.lua`.

Build services may depend on `Domain`, `PZ`, `Runtime` primitives and `Services/Common`, but must not depend on `Services/Moveables` merely to identify or understand an opening.

The Garage Build implementation is intentionally split into separate concerns rather than one large service: build/profile context, length state, resource requirements, face proxying and finalization.

## `LMION/Services/Moveables/...`

Responsibility: pickup/replacement transport behavior and Moveables-specific profiles.

Family-specific code is grouped by family:

```text
Services/Moveables/Garage/
Services/Moveables/LargeGate/
Services/Moveables/SingleTileDoor/
```

Shared Moveables-only field conversion remains in `Services/Moveables/MoveableProfileFields.lua`.

Moveables services enrich neutral definition information with transport-only facts such as parcel item types, tools, pickup skill level and package weight. Build does not consume those enriched profiles.

## `LMION/PZ/...`

Responsibility: narrow low-level adapters around Project Zomboid objects and engine-visible identity.

The PZ layer must not depend upward on a gameplay subsystem such as Build or Moveables. Workflow-specific lookups belong to the owning service instead. For example, LargeGate post-build part lookup lives under `Services/Build/LargeGate/BuiltPart.lua`, not under `PZ`.

## Client UI and hooks

Client UI implementations and vanilla integration hooks are separate responsibilities:

```text
client/LMION/UI/Build/GarageLengthSelector.lua
client/LMION/Hooks/Build/GarageBuildUI.lua
client/LMION/Keybinds/GaragePlacement.lua
client/LMION/Hooks/Moveables/GarageContextMenu.lua
```

A UI widget does not also own unrelated monkey patches or ModOptions registration.

## Server Moveables cursors

Dedicated cursor/action implementations remain in the server realm where they already worked, but are no longer misclassified as hooks:

```text
server/LMION/Moveables/GarageCursor.lua
server/LMION/Moveables/LargeGateCursor.lua
```

No client/server/shared realm change was made during this organization pass.

## `LMION_DEV.lua`

Responsibility: tiny mod bootstrap entrypoint.

It loads the public API and bootstraps the active systems. Detailed gameplay behavior belongs in the corresponding services/runtime/hooks, not in the entrypoint.

## Current boundary

The V3 foundation is no longer data-only. Active code now includes definitions, Build integration, Moveables pickup/replacement, canonical `IsoDoor` conversion, LargeGate runtime state preservation, Garage variable-length behavior and narrow PZ adapters.

The architectural rule is now explicit:

```text
                 Services/Common
                /               \
             Build             Moveables
              |                    |
     family-specific code   family-specific code
```

Build and Moveables may share neutral rules through `Services/Common`; neither subsystem should depend on the other for opening identity, geometry or placement policy.
