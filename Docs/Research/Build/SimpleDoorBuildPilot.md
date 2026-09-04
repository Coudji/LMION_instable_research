# Simple 1x1 Build pilot — White Panel Door

Status: control points recovered from validated Legacy Build behavior; V3 implementation pending runtime validation.

Purpose of this pilot: make `Doors.Wood.WhitePanelDoor` constructible through vanilla Build so the first Simple pickup/replacement checkpoint does not require finding a matching door in the world.

## Vanilla path

The validated Legacy Build path uses the vanilla GameEntity/CraftRecipe pipeline and `ISBuildIsoEntity`:

```text
media/scripts CraftRecipe on Base.WhitePanelDoor
-> vanilla Build menu / cursor
-> ISBuildIsoEntity.isValid(...)
-> ISBuildIsoEntity.isValidPerSquare(...)
-> vanilla timed construction
-> ISBuildIsoEntity.setInfo(...)
-> LMION post-build finalization
```

Vanilla remains responsible for Build UI, cursor rotation, timed action, skills, tool/material consumption and initial world-object creation.

## Why LMION intervenes

The White Panel Door definition is `doorType = Simple`, therefore V3 requires:

- placement only on a matching standard door frame;
- canonical final representation as `IsoDoor`;
- fresh-construction durability derived from the definition and the relevant construction skill;
- fresh construction must not inherit transient lock state from the temporary engine object.

These rules already belong to the shared runtime layer; the Build hook only connects `ISBuildIsoEntity` to them.

## Recipe source

Legacy known-good recipe data for White Panel Door:

```text
time = 150
Woodwork 6
XP 35
hammer kept
screwdriver kept
4 planks
4 nails
2 hinges
4 screws
1 doorknob
```

This matches the effective V3 catalog definition `Doors.Wood.WhitePanelDoor` inherited from `Doors.Wood.FourPanels`.

The V3 pilot uses vanilla `Build_DoorWood` as the Build-menu icon instead of migrating a release texture solely for this temporary pilot.

## Exact hook owner

```text
media/lua/server/LMION/Hooks/Build/SimpleDoor.lua
```

The hook is server-tree because vanilla `BuildingObjects/ISBuildIsoEntity.lua` is server-tree and is not safely require-able during the initial shared/client phase.

### `ISBuildIsoEntity.isValid(square)`

Call vanilla first. For `Base.WhitePanelDoor` only, additionally require `Runtime/DoorPlacement.canPlaceSimpleAt(square, facing)`.

### `ISBuildIsoEntity.isValidPerSquare(...)`

Call vanilla first, then apply the same Simple frame rule so the Build cursor visually agrees with the final validity result.

### `ISBuildIsoEntity.setInfo(...)`

Call vanilla first. After the initial object exists, locate the built `Base.WhitePanelDoor` on the completed square and delegate to the Simple Build finalizer.

## Finalization

The finalizer:

```text
temporary door
-> CanonicalDoor.ensure(... preserveLockState=false)
-> compute effective construction max health
-> set logical max health
-> set current health to that max
-> transmit completed door when applicable
```

Construction durability follows the validated Legacy formula:

```text
maxHealth = durability.health + durability.skillBaseHealth * relevantSkillLevel
```

For White Panel Door that means base `450` plus `275 * Woodwork level`.

## Runtime logs

The pilot should emit only meaningful boundaries:

```text
Simple Build hook installed
Simple Build finalizing: definition=Doors.Wood.WhitePanelDoor ...
Simple Build finalized: ... representation=IsoDoor health=... max=...
```

No per-frame Build validity spam.

## Validation scope

The next cold-start checkpoint can validate both sides with one constructed pilot door:

```text
Build White Panel Door
-> confirm frame requirement + IsoDoor finalization
-> damage it
-> Pickup
-> replace with Moveables
-> confirm N/W rotation + preserved durability
```

Sources: Legacy `LMION_Build/media/scripts/WhitePanelDoor_Build.txt`, Legacy `LMION_Build/media/lua/server/LMION/BuildHook.lua`, Legacy `LMION_Core/Doors/Construction.lua`, Legacy `LMION_Core/Doors/Durability.lua`, active load-order research.
