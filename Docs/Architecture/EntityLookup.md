# Entity lookup foundation

This slice connects Project Zomboid GameEntity identity to registered LMION definitions without adding gameplay behavior or vanilla hooks.

## Files

### `Definitions/Registry.lua`

The registry still only owns registered raw data. It now also exposes a monotonically increasing `revision` number.

The revision changes after every successful default, definition or extension registration. It does not know which derived caches exist and does not invalidate them directly.

### `Definitions/EntityIndex.lua`

Owns one derived fact:

```text
GameEntity full name -> definitionId
```

It builds from effective definitions, checks entity collisions and rebuilds lazily when the Registry revision changes.

It understands only the identity-bearing fields already present in the current schema: `entity`, `entities.left` and `entities.right`.

It does not read world objects and does not call PZ APIs.

### `PZ/WorldObjectIdentity.lua`

Owns the narrow Project Zomboid adapter:

```text
world object -> object:getEntityScript():getFullName()
```

It knows nothing about the LMION registry or definition resolution.

### `Services/DefinitionLookup.lua`

Combines the pure EntityIndex with the PZ object identity adapter to answer the actual lookup use cases exposed by the API.

It does not mutate objects, place doors, inspect sprites or install hooks.

### `API.lua`

The public facade now exposes entity-level and object-level lookup methods. External addons still do not need to require any internal module.

## Dependency direction

```text
API
 -> Services/DefinitionLookup
     -> Definitions/EntityIndex
         -> Registry + Resolver
     -> PZ/WorldObjectIdentity
```

The PZ adapter does not depend on the registry. The registry does not depend on derived indexes.

## No runtime takeover

This foundation installs no event and monkey-patches nothing. PZ remains entirely in control; LMION only reads identity when a caller asks for it.
