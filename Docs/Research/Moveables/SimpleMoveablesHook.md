# Simple 1x1 Moveables integration — V3 control points

Status: core White Panel Door loop **VALIDÉ EN JEU** on 2026-09-04; generic-flatpack transport change implemented on 2026-09-05 and **NON VALIDÉ EN JEU**.

This note is the required control-point map for V3's Simple vanilla Moveables hooks.

## Vanilla path

For a normal single-sprite Moveable, vanilla flows through `ISMoveableSpriteProps`:

```text
new(sprite)
-> Moveables metadata
-> canPlaceMoveableInternal(...)
-> pickUpMoveableInternal(...)
-> instanceItem(...)
-> placeMoveableInternal(...)
```

Vanilla continues to own the action/cursor lifecycle, action duration, inventory capacity, tool checks, skill checks, removal/item creation and the initial placed object.

## Why LMION intervenes

A supported LMION Simple door needs information vanilla Moveables does not own:

- LMION definition identity;
- canonical N/W closed faces from explicit definition geometry;
- exact source health/effective max-health transport;
- a standard matching door frame at the target square;
- canonical `IsoDoor` final representation after placement.

These are LMION responsibilities; the Moveables hook only connects vanilla to the already separated runtime/services.

## Exact intercepted methods

### `ISMoveableSpriteProps.new(sprite)`

After vanilla creates `moveProps`, LMION attaches a Simple-door Moveables profile when the sprite resolves to an eligible Simple definition.

Vanilla creation remains authoritative and is always called first.

The profile sets the vanilla `customItem` boundary to the generic transport item `Base.LMION_Flatpack`. It does not overwrite the world object's Moveables name from the flatpack script, because world identity and transport identity are separate.

### `hasFaces()` / `getFaces()`

For an LMION Simple door only, LMION exposes the definition's explicit closed N/W faces so vanilla keeps its normal rotation/cursor behavior.

Unknown/non-LMION moveables always call the previous implementation.

### `pickUpMoveableInternal(...)`

Immediately before vanilla pickup, LMION captures normalized source door state. The pending snapshot exists only while vanilla performs that pickup.

Vanilla still removes the world object and decides when `instanceItem()` is called.

### `instanceItem(...)`

LMION supplies the canonical closed sprite for the current N/W facing, then calls vanilla item creation.

After vanilla returns the generic `Base.LMION_Flatpack`, `Services/Moveables/SimpleDoorFlatpack` prepares it by:

```text
writing lmionDoorDefinitionId
writing transported durability state
restoring the generic Flatpack display name
applying the definition package weight
```

The generic item type is therefore an engine transport container; the door definition is carried explicitly in modData.

### `canPlaceMoveableInternal(...)`

For an LMION Simple door, LMION first requires the flatpack's stored definition identity to match the current Simple profile. It then replaces vanilla's spatial placement decision because vanilla does not express the required standard-frame contract. LMION checks its separated `Runtime/DoorPlacement` service, then preserves the same vanilla Moveables skill/tool checks.

This matched-LMION branch intentionally does not call the previous spatial validator. Unknown/non-LMION moveables always call the previous implementation.

This method can run repeatedly while the cursor moves, so V3 must not emit per-call logs from this boundary.

### `placeMoveableInternal(...)`

LMION verifies flatpack identity again at the actual placement boundary. A mismatch is rejected before vanilla placement and logs `reason=flatpack-identity`.

For a valid parcel, LMION selects the explicit closed sprite for the current facing and calls vanilla placement first. After vanilla creates the object, LMION finalizes the result through the canonical-door/durability services.

## Owner

One file owns these wrappers:

```text
Hooks/Moveables/SimpleDoor.lua
```

It must stay a thin adapter. Frame scanning, durability, transport identity, flatpack preparation, canonicalization, profile derivation and placed-door lookup live elsewhere.

Relevant delegated modules now include:

```text
Runtime/Moveables/DoorTransportState.lua
Runtime/Moveables/DoorTransportIdentity.lua
Services/Moveables/SimpleDoorFlatpack.lua
Services/Moveables/SimpleDoorPlacementFinalizer.lua
```

## Load timing

The Legacy Simple path successfully required `Moveables/ISMoveableSpriteProps` from shared Lua. V3 keeps the reusable hook installer in shared Lua and installs it from the shared DEV bootstrap.

Door sprite `IsMoveAble` properties are applied only from `OnLoadedTileDefinitions`, because tile-derived sprite state is not treated as stable earlier.

## First V3 runtime failure

**ÉCHEC TESTÉ / NE PAS REFAIRE** — 2026-09-04, B42.20.x.

The first cold start reached:

```text
[LMION:DEV] Simple Moveables hooks installed
[LMION:DEV] definitions ready: 23 defaults, 72 definitions, 0 extensions
[LMION:DEV] entity index ready: 77 mappings; Base.WhitePanelDoor -> Doors.Wood.WhitePanelDoor
```

Then `OnLoadedTileDefinitions` called `SimpleDoorSprites.configure()`, which built the Simple profile index. `SimpleDoorProfiles.getSingleSkillLevel()` used the global Lua `next()` function and Kahlua reported:

```text
Object tried to call nil in getSingleSkillLevel
```

The failure happened before any world Pickup/placement path was exercised. Fix: iterate the skill table with `pairs()` and count entries explicitly instead of relying on global `next()`.

This failure did **not** invalidate the catalog or entity reverse index; both completed before the event error.

## VALIDÉ EN JEU — original complete White Panel Door loop

2026-09-04, before the generic-flatpack refactor.

The successful cold-start console contained:

```text
[LMION:DEV] Simple Moveables hooks installed
[LMION:DEV] definitions ready: 23 defaults, 72 definitions, 0 extensions
[LMION:DEV] entity index ready: 77 mappings; Base.WhitePanelDoor -> Doors.Wood.WhitePanelDoor
[LMION:DEV] Simple Moveables sprites configured: 4
```

The user then constructed a White Panel Door, picked it up and replaced it successfully. Runtime logs showed:

```text
[LMION:DEV] Simple pickup state captured: definition=Doors.Wood.WhitePanelDoor health=725 max=725
[LMION:DEV] Simple transport item serialized: definition=Doors.Wood.WhitePanelDoor item=Base.LMION_WhitePanelDoor
[LMION:DEV] Simple placement started: definition=Doors.Wood.WhitePanelDoor facing=W sprite=fixtures_doors_01_0
[LMION:DEV] Simple placement finalized: definition=Doors.Wood.WhitePanelDoor sprite=fixtures_doors_01_0 health=725 max=725
```

User validation confirmed:

- pickup works;
- replacement works;
- the standard frame requirement is enforced correctly;
- HP/max-HP persist through pickup and replacement.

This validated the integrated `GameEntity -> definition -> Simple profile -> vanilla Moveables -> LMION finalization` path. It did not validate the later generic-flatpack item representation.

## NON VALIDÉ — generic flatpack checkpoint

2026-09-05 implementation changes transport identity from one technical item per door to:

```text
Base.LMION_Flatpack
+ lmionDoorDefinitionId
+ durability modData
```

The Simple profile remains explicitly gated to `Doors.Wood.WhitePanelDoor` until this path is validated. Do not claim catalog-wide Simple support yet.

Expected serialization log:

```text
[LMION:DEV] Simple flatpack serialized: definition=Doors.Wood.WhitePanelDoor item=Base.LMION_Flatpack prepared=true
```

See `Docs/Research/Moveables/FlatpackTransport.md`.

## Restart requirement

The generic-flatpack pilot adds/changes `media/scripts`, so its first validation requires a cold PZ restart. Group that validation with the complete Build -> damage -> pickup -> replace cycle rather than requesting additional launches for individual Lua modules.

## Runtime logs

Keep meaningful boundaries during unstable development:

```text
Simple Moveables hooks installed
Simple Moveables sprites configured
Simple pickup state captured
Simple flatpack serialized
Simple placement rejected (identity mismatch only)
Simple placement started
Simple placement finalized
```

No per-frame placement-validation spam.

Sources: active `Docs/Research/Architecture/DoorObjectAbstraction.md`, active `Docs/Research/Moveables/VanillaMoveablesBehavior.md`, active `Docs/Research/Moveables/FlatpackTransport.md`, Legacy `LMION/Pickup/Doors/Hooks.lua`, Legacy `LMION/Pickup/Doors/Registry.lua`, B42.20.3 engine/script inspection, and the 2026-09-04 runtime consoles.
