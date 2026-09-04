# Simple 1x1 Moveables integration — V3 control points

Status: implementation target recovered from validated Legacy behavior; first V3 cold-start reached hook installation/index diagnostics, then failed during `OnLoadedTileDefinitions` profile construction. Fix committed; full Simple cycle still pending runtime validation.

This note is the required control-point map before V3 installs its first vanilla Moveables hooks.

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

**ÉCHEC TESTÉ / NE PAS REFAIRE** — 2026-09-04, B42.20.4.

Cold start reached:

```text
[LMION:DEV] Simple Moveables hooks installed
[LMION:DEV] definitions ready: 23 defaults, 72 definitions, 0 extensions
[LMION:DEV] entity index ready: 77 mappings; Base.WhitePanelDoor -> Doors.Wood.WhitePanelDoor
```

Then `OnLoadedTileDefinitions` called `SimpleDoorSprites.configure()`, which built the Simple profile index. `SimpleDoorProfiles.getSingleSkillLevel()` used the global Lua `next()` function and Kahlua reported:

```text
Object tried to call nil in getSingleSkillLevel
```

So the failure happened before any world Pickup/placement path was exercised. The game continued loading because the event callback error was contained.

Fix: iterate the skill table with `pairs()` and count entries explicitly instead of relying on global `next()`.

This failure does **not** invalidate the catalog or entity reverse index; both completed before the event error.

## Restart requirement

The first V3 pilot adds a new `media/scripts` inventory item definition. A cold PZ restart remains required for the next meaningful runtime validation. Lua reload alone is not sufficient evidence for that checkpoint.

## Runtime logs

The first validation should log only meaningful boundaries:

```text
Simple Moveables hooks installed
Simple Moveables sprites configured
Simple pickup state captured
Simple transport item serialized
Simple placement started
Simple placement finalized
```

No per-frame placement-validation spam.

Sources: active `Docs/Research/Architecture/DoorObjectAbstraction.md`, active `Docs/Research/Moveables/VanillaMoveablesBehavior.md`, Legacy `LMION/Pickup/Doors/Hooks.lua`, Legacy `LMION/Pickup/Doors/Registry.lua`, and the 2026-09-04 B42.20.4 runtime console.
