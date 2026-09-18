# LMION V3 architecture

This directory documents the **current** V3 architecture only. Historical V1/V2 architecture remains in `Coudji/LMION_Legacy` and detailed implementation archaeology belongs under `Docs/Research/`.

## Product shape

LMION V3 is one gameplay mod. Pickup/Moveables, Build and future systems are internal subsystems of that product, not independently enabled mods.

One installed mod does **not** mean one giant runtime layer.

## Code organization rules

- one file = one identifiable responsibility;
- functions stay short and intention-revealing;
- vanilla hooks are narrow adapters, not business-logic containers;
- one owner per vanilla behavior boundary;
- prefer delegating back to vanilla whenever vanilla still does the correct job;
- family-specific mechanics stay family-specific when their contracts materially differ;
- `Services/Common` exists only for facts/rules genuinely shared by independent subsystems;
- Build and Moveables do not depend on each other;
- avoid universal routers/managers/bridges that accumulate unrelated family behavior;
- internal organization optimizes for human navigation first;
- do not move a file between `client`, `server` and `shared` merely for naming neatness.

## Current source shape

```text
LMION/
├─ API.lua
├─ Bootstrap/
├─ Definitions/
├─ Domain/
├─ Hooks/
├─ PZ/
├─ Runtime/
└─ Services/
   ├─ Build/
   │  ├─ Garage/
   │  ├─ LargeGate/
   │  └─ SingleTileDoor/
   ├─ Common/
   │  ├─ Garage/
   │  ├─ LargeGate/
   │  └─ SingleTileDoor/
   └─ Moveables/
      ├─ Garage/
      ├─ LargeGate/
      └─ SingleTileDoor/
```

See `FoundationFiles.md` for detailed ownership and `DoorRuntimeFoundation.md` for the active door/runtime boundaries.

## Public/private boundary

Third-party addons use:

```lua
local LMION = require "LMION/API"
```

Anything not deliberately exposed through that API is internal and may change. Public definitions remain small, data-first and semantic; Project Zomboid implementation details stay internal when they can be derived.

## Active decisions

Important current contracts include:

```text
Docs/Decisions/BuildRecipesAndVariants.md
Docs/Decisions/CanonicalDoorsAndLargeGates.md
Docs/Decisions/LargeGatePlacementSpace.md
```

The Build recipe/variant decision defines definition-owned construction data, vanilla-facing categories, presentation-only variant grouping and the hidden-variant sequential-build behavior.

The LargeGate placement decision explicitly separates leaf placement validity from partner inference and documents the native 2x2 swing-space rule and its deliberate scope boundary.
