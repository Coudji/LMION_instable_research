# V3 GameEntity and world-object lookup

Status: active V3 research guardrail, migrated from Legacy on 2026-09-04.

## Purpose

Gameplay systems usually receive a Project Zomboid world object, not an LMION `definitionId`.

The supported identity chain is:

```text
IsoObject / IsoDoor
-> GameEntityScript full name
-> LMION definitionId
-> effective definition
```

This layer identifies an opening. It does not place, remove, canonicalize or mutate the world object.

## Engine identity path

**OBSERVÉ DANS VANILLA / SOURCE**

Build 42 exposes the following path on world objects:

```text
IsoObject extends GameEntity
GameEntity.getEntityScript()
GameEntityScript.getFullName()
```

Therefore the canonical object identity read is:

```lua
local entityScript = object:getEntityScript()
local entityId = entityScript:getFullName()
```

The current sprite must not be used as the primary identity key. An opened door can change sprite while its GameEntity identity remains stable.

Sprite and geometry data remain necessary for orientation, placement and multipart topology. They are not the primary definition lookup key.

## Lookup behavior

V3 preserves these Legacy contracts:

- a nil world object is a caller error;
- an object without an EntityScript returns `nil`;
- an EntityScript without a usable full name returns `nil`;
- an unknown but otherwise valid GameEntity ID returns `nil`;
- two different definitions claiming the same GameEntity ID is an error because the identity would be ambiguous.

The public API may expose both entity-level and object-level lookup forms. Internal runtime code should not reproduce this chain independently.

## Definition fields currently carrying GameEntity identity

The migrated V3 catalog currently uses:

```lua
entity = "Base.WhitePanelDoor"
```

and Paired definitions use explicit member entities:

```lua
entities = {
    left = "Base.GreyMetalDoubleDoorLeft",
    right = "Base.GreyMetalDoubleDoorRight",
}
```

Both Paired member entities map to the same conceptual `definitionId`.

Garage and LargeGate definitions currently also retain their reviewed primary `entity` identity from the catalog. Exact runtime member/script representation for those families remains a later subsystem concern and must not be invented by this lookup layer.

## Effective definitions and index freshness

The reverse index must be derived from **effective definitions**, not raw catalog tables, because defaults and extensions can affect the final registered data.

Legacy V2 invalidated the index after every registration and rebuilt lazily, with an additional explicit rebuild during `OnGameBoot`.

For V3, no lifecycle hook is required merely to keep a pure reverse index fresh. A registry revision counter can let the index detect new registrations/extensions and rebuild lazily on the next lookup. This keeps the dependency one-way:

```text
EntityIndex -> Registry / Resolver
```

instead of making `Registry` or the public API know which derived indexes must be invalidated.

If later PZ diagnostics require an `OnGameBoot` validation pass against `ScriptManager`, that is a separate diagnostic/lifecycle responsibility and must be added explicitly rather than hidden inside lookup.

## Historical runtime evidence

**VALIDÉ EN JEU — LEGACY / HISTORICAL**

The first V2 live validation reported:

```text
23 defaults
54 definitions
58 indexed GameEntity mappings
56/58 GameEntities found in ScriptManager
```

The two missing mappings were then:

```text
Base.LargeWroughtIronGate
Base.LargeHardenedWoodenGate
```

Those counts belong to the historical V2 catalog state. They are **not** expected V3 counts: the current migrated V3 catalog contains 23 defaults and 72 concrete definitions.

What this historical test validates is the identity mechanism (`getEntityScript():getFullName()` -> reverse index), not the old counts.

## Vanilla boundary for this layer

There is no monkey-patch or vanilla hook in the lookup layer.

LMION takes no control from vanilla here. It only reads an object's existing GameEntityScript when a caller asks for identity.

Consequently this foundation does not require a special load phase by itself. Any future startup validation against `ScriptManager` must follow the lifecycle research separately.

## Do not retry

- Do not identify a door definition from its current sprite when a GameEntityScript is available.
- Do not world-scan arbitrary objects to guess LMION ownership.
- Do not silently allow two definitions to claim the same GameEntity ID.
- Do not couple the raw registry to every derived runtime index through a growing invalidation list.
