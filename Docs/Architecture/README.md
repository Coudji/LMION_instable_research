# LMION V3 architecture

This directory documents the **current** V3 architecture only.
Historical V1/V2 architecture remains in `Coudji/LMION_Legacy`.

## Product shape

LMION V3 is one gameplay mod. Official systems such as Pickup, Build and future Lock are internal domains of that one product, not independently enabled mods.

One installed mod does **not** mean one Lua file or one giant runtime layer.

## Code organization rules

- one file = one identifiable responsibility;
- functions stay short and intention-revealing;
- vanilla hooks are narrow adapters, not business-logic containers;
- one owner per vanilla behavior boundary;
- prefer delegating back to vanilla whenever vanilla still does the correct job;
- family-specific mechanics stay family-specific when their contracts materially differ;
- shared helpers exist only for genuinely shared mechanical contracts;
- avoid universal routers/managers/bridges that accumulate family branches;
- pure structural moves/refactors and behavior changes should be separate operations;
- internal organization optimizes for human navigation first.

## Public/private boundary

Third-party addons should ultimately use:

```lua
local LMION = require "LMION/API"
```

Anything not deliberately exposed through the public API is internal and may change.

The public API should remain small, data-first and versioned. Do not expose Project Zomboid implementation details merely because LMION internally needs them.

## Initial source-map direction

Exact folders will be created only as responsibilities become real, but the intended separation is approximately:

```text
LMION/
├─ API/
├─ Definitions/
├─ Domain/
├─ Runtime/
├─ Services/
├─ Hooks/
├─ UI/
├─ PZ/
└─ Persistence/
```

Family-specific subfolders are preferred where they make ownership obvious.

Do not create speculative empty abstractions for systems that do not exist yet.
