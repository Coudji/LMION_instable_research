# Simple 1x1 Moveables integration — V3 control points

Status: **VALIDÉ EN JEU** for the White Panel Door pilot on 2026-09-04.

This note is the required control-point map for V3's first vanilla Moveables hooks.

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

### `hasFaces()` / `getFaces()`

For an LMION Simple door only, LMION exposes the definition's explicit closed N/W faces so vanilla keeps its normal rotation/cursor behavior.

Unknown/non-LMION moveables always call the previous implementation.

### `pickUpMoveableInternal(...)`

Immediately before vanilla pickup, LMION captures normalized source door state. The pending snapshot exists only while vanilla performs that pickup.

Vanilla still removes the world object and decides when `instanceItem()` is called.

### `instanceItem(...)`

LMION supplies the canonical closed sprite for the current N/W facing, then calls vanilla item creation. After vanilla returns the item, LMION writes transported durability to item modData.

### `canPlaceMoveableInternal(...)`

For an LMION Simple door, LMION replaces vanilla's spatial placement decision because vanilla does not express the required standard-frame contract. LMION checks its separated `Runtime/DoorPlacement` service, then preserves the same vanilla Moveables skill/tool checks.

This matched-LMION branch intentionally does not call the previous spatial validator. Unknown/non-LMION moveables always call the previous implementation.

This method can run repeatedly while the cursor moves, so V3 must not emit per-call logs from this boundary.

### `placeMoveableInternal(...)`

LMION selects the explicit closed sprite for the current facing and calls vanilla placement first. After vanilla creates the object, LMION finalizes the result through the canonical-door/durability services.

## Owner

One file owns these wrappers:

```text
Hooks/Moveables/SimpleDoor.lua
```

It must stay a thin adapter. Frame scanning, durability, canonicalization, profile derivation and placed-door lookup live elsewhere.

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

## VALIDÉ EN JEU — complete White Panel Door loop

2026-09-04, after the profile fix and Build pilot completion.

The successful cold-start console contains:

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

User validation additionally confirmed:

- pickup works;
- replacement works;
- the standard frame requirement is enforced correctly;
- HP/max-HP persist through pickup and replacement.

This validates the first integrated `GameEntity -> definition -> Simple profile -> vanilla Moveables -> LMION finalization` path. It does not yet prove every Simple definition, Paired, FenceGate, Sliding, Garage or LargeGate.

## Restart requirement

The pilot contains a `media/scripts` inventory item definition. A cold PZ restart was required for this validation and has now been performed successfully.

Further pure-Lua/data expansion should be grouped before requesting another restart. A new restart is required only when the next meaningful integrated milestone or new `media/scripts` topology needs it.

## Runtime logs

Keep meaningful boundaries during unstable development:

```text
Simple Moveables hooks installed
Simple Moveables sprites configured
Simple pickup state captured
Simple transport item serialized
Simple placement started
Simple placement finalized
```

No per-frame placement-validation spam.

Sources: active `Docs/Research/Architecture/DoorObjectAbstraction.md`, active `Docs/Research/Moveables/VanillaMoveablesBehavior.md`, Legacy `LMION/Pickup/Doors/Hooks.lua`, Legacy `LMION/Pickup/Doors/Registry.lua`, and the 2026-09-04 runtime consoles.
