# LMION V3 current state / conversation handoff

Last updated: 2026-09-11

This file is the canonical handoff for active V3 development in `Coudji/LMION_instable_research`.

## Repository roles

- `Coudji/LMION_instable_research` — active V3 development repository.
- `Coudji/LMION_Legacy` — **functional behavioral oracle**. When a gameplay behavior conflicts with a refactor-era idea, the validated Legacy behavior wins.
- `LMION_Legacy/Workshop` — previous refactor attempt. It may contain useful research/code ideas, but it is not the gameplay oracle.
- do not modify Legacy unless explicitly requested.

Current dev mod:

```text
Workshop title: Let Me In... Or Not [DEV]
Mod id:         LMION_DEV
Mod folder:     Contents/mods/LMION_DEV
```

## Non-negotiable refactor rules

V3 must reproduce the known-good in-game behavior with simpler and more maintainable code.

- one gameplay mod; no old Core/Pickup/Build split into separate mods;
- simple functions with clear names;
- one function = one identifiable responsibility;
- one file = one identifiable responsibility;
- split files before they become difficult for a human to read;
- hooks are thin adapters around a real vanilla boundary;
- one vanilla boundary should have one owner;
- no catch-all routers/managers/bridges;
- no speculative abstractions before duplicate behavior is proven;
- public definitions contain semantic/data facts, not derivable runtime implementation details;
- external addon modders must be able to understand the API and conventions without reading accidental internals;
- keep research/handoff documents current;
- record failed approaches so later conversations do not repeat them;
- when engine behavior is uncertain, inspect B42 vanilla Lua and/or the supplied `projectzomboid.jar` instead of guessing.

## Canonical opening rules

- every final LMION-managed opening is an `IsoDoor`;
- `IsoThumpable(isDoor)` is accepted only as source/vanilla/external input at a narrow boundary;
- HP/max HP survive pickup/replacement;
- Simple requires a standard frame;
- Paired has independent `left` / `right` 1x1 leaves and matching paired frame sides;
- FenceGate and Sliding require no frame;
- LargeGate uses stable logical leaf identity `A` / `B`, never left/right;
- Garage uses explicit START/MIDDLE/END geometry.

Semantic `doorType` values:

```text
Simple
Paired
FenceGate
Sliding
LargeGate
Garage
```

Internal frame consequence:

```text
Simple    -> standard
Paired    -> paired
FenceGate -> none
Sliding   -> none
LargeGate -> none
Garage    -> none
```

Do not restore redundant public frame/topology fields when the consequence can be derived internally.

Canonical decision: `Docs/Decisions/CanonicalDoorsAndLargeGates.md`.

## Data/API foundation — VALIDATED

External addons use:

```lua
local LMION = require "LMION/API"
```

Current built-in catalog:

```text
23 defaults
72 definitions
0 built-in extensions
```

By family:

```text
Doors/Paired          5
Doors/Single/Metal   16
Doors/Single/Wooden  27
FenceGates            9
GarageDoors           7
LargeGates            6
SlidingDoors          2
```

GameEntity reverse lookup is validated for the existing indexed identities:

```text
world object
-> object:getEntityScript():getFullName()
-> EntityIndex
-> definitionId
-> effective definition
```

Known validated startup diagnostics include:

```text
[LMION:DEV] definitions ready: 23 defaults, 72 definitions, 0 extensions
[LMION:DEV] entity index ready: 77 mappings; Base.WhitePanelDoor -> Doors.Wood.WhitePanelDoor
```

## Definitions / addon-facing rules

Definitions/defaults are pure data with explicit identities:

```text
definitionId
defaultId
extensionId
```

`doorType` is the semantic discriminator. Runtime frame/topology/placement consequences are derived internally where possible.

Paired definitions explicitly override inherited `doorType = "Simple"` with `doorType = "Paired"`. They do not expose a public frame side/topology field because their geometry already defines left/right.

LargeGate definitions expose exact N/W A/B geometry but not implementation-specific parcel or topology fields.

Validation is intentionally still structural/minimal. Full strict schema validation is deferred until the public API shape is complete.

## Single-tile integrated checkpoint — VALIDATED IN GAME

Current runtime-proven pilots:

```text
Doors.Wood.WhitePanelDoor
Doors.Wood.BlueChurchDoubleDoor
FenceGates.Wood.SmallWhiteWoodenGate
SlidingDoors.BrownSlidingGlassDoor
```

Validated behavior across those pilots as applicable:

```text
Build
Pickup
replacement
N/W placement/rotation
standard/paired/no-frame rules
HP/max-HP persistence
MetalWelding Moveables tool bridge
canonical final IsoDoor
```

This validates the architecture and those pilots, not every catalog definition.

The one-entity Moveables profile provider covers identical Simple/FenceGate/Sliding shapes when the matching transport script item exists. Paired remains separate because it has two entities/members.

## Script convention

Use one PZ script file per opening/family rather than separate `_Item`, `_Build`, `_Entity` files.

The script file contains only parse-time facts PZ actually needs, such as:

```text
transport item declarations
XUI
CraftRecipe
SpriteConfig
```

LMION Lua definitions remain authoritative for semantic type, durability, geometry and gameplay data.

## LargeGate runtime — IMPLEMENTED, INTEGRATED RE-TEST PENDING

LargeGate V3 now has family-specific services for:

```text
profile/segment lookup
A/B topology
runtime closed SpriteGrids
leaf pickup
parcel lookup/consumption
placement planning
partner open/closed detection
placement finalization
Moveables ghost rendering
Build leaf GameEntities/finalization
```

Legacy remains the functional contract:

```text
pickup/replacement per A/B leaf
2 physical members/parcels per leaf
inventory + nearby-floor parcel lookup
N/W behavior
partner-state coherence
HP/max-HP persistence
```

### First integrated placement test — FAILED on 5841a976

Tested commit:

```text
5841a976ae8d2cf7f1928825fd266f76158c1b00
```

Observed:

```text
LargeGate pickup produced parcels.
Placement failed from inventory right-click.
Placement failed from the vanilla Moveables toolbar.
```

The common upstream defect was the transport identity introduced during the V3 implementation:

```text
all segments -> Base.LMION_OpeningParcel
identity only in modData
no Moveable WorldSprite assigned
```

Vanilla Moveables reconstructs placement props from `item:getWorldSprite()`. The generic parcel therefore could not correctly enter either placement frontend.

**FAILED APPROACH / DO NOT REINTRODUCE:** a universal LargeGate `LMION_OpeningParcel` that replaces the engine-visible segment identity.

### LargeGate transport correction — 2026-09-11

V3 is returning to the known-good Legacy parcel model while keeping the new architecture simple:

```text
LMION_<Gate>A_Part1
LMION_<Gate>A_Part2
LMION_<Gate>B_Part1
LMION_<Gate>B_Part2
```

Differences from old architecture:

- declarations live in the corresponding LargeGate script file;
- item names are derived internally from the semantic entity instead of being duplicated in public definitions;
- each item uses `Icon = Flatpack` only as presentation;
- parcel factory calls `ReadFromWorldSprite(closedSegmentSprite)` so vanilla Moveables receives the identity it expects;
- LMION modData still stores definition/leaf/part and durability state;
- the generic `OpeningParcel` item is removed.

This correction is **NOT YET VALIDATED IN GAME**. Do not mark LargeGate replacement functional until both placement frontends pass.

Research:

```text
Docs/Research/Moveables/FlatpackTransport.md
Docs/Research/Moveables/VanillaMoveablesBehavior.md
Docs/Research/Moveables/LargeGateGhostRendering.md
```

## LargeGate Build status

LargeGate Build code exists, including vanilla full-gate narrowing for supported vanilla entities, A/B GameEntity profiles and post-build canonicalization.

It remains **NOT VALIDATED IN GAME** as an integrated LargeGate Build checkpoint. Keep Build validation separate from the Moveables replacement test.

## Garage status

Garage definitions/defaults are migrated, but Garage V3 runtime is not yet ported.

Legacy Garage remains the contract, including:

```text
inventory placement -> variable width
toolbar placement -> intentionally fixed L3
N/W
START/MIDDLE*/END parcels
inventory + nearby-floor parcel lookup
transactional placement/rollback
HP persistence
```

Do not redesign Garage behavior from the V3 LargeGate implementation.

## Historical failures / do not repeat

**TESTED FAILURE / DO NOT REPEAT:**

- Kahlua global `next()` was nil in a profile path. Use `pairs()` + explicit counting.
- Build CraftRecipe without a GameEntity SpriteConfig can appear in the menu but clicking Build produces no cursor.
- V2 LargeGate toolbar could show a complete ghost while click placement failed; do not resume speculative V2 patches.
- V3 generic `Base.LMION_OpeningParcel` without `ReadFromWorldSprite()` broke both LargeGate placement frontends on commit `5841a976...`.

General rule: if the engine contract is uncertain, inspect vanilla Lua/JAR first and record the result here or in `Docs/Research`.

## Validation summary

**VALIDATED IN GAME:**

- built-in catalog startup 23/72/0;
- existing GameEntity reverse lookup checkpoint;
- White Panel Simple pilot;
- Blue Church Paired pilot;
- Small White Wooden FenceGate pilot;
- Brown Sliding Glass Door pilot;
- N/W behavior for those pilots;
- their frame/no-frame contracts;
- HP/max-HP persistence for those pilots;
- MetalWelding Moveables tool bridge through Sliding.

**IMPLEMENTED BUT NOT YET VALIDATED AS A COMPLETE CHECKPOINT:**

- LargeGate Moveables runtime after the 2026-09-11 transport correction;
- LargeGate Build runtime.

**NOT YET IMPLEMENTED/VALIDATED BROADLY:**

- remaining Simple definitions;
- remaining Paired definitions;
- remaining FenceGate definitions;
- remaining Sliding definitions;
- Garage V3 runtime.

## Immediate next test

Before any new family/refactor work, cold-start test a LargeGate replacement through both entry points:

```text
1. Pickup one A or B leaf -> 2 parcels.
2. Inventory right-click -> Place.
3. Moveables toolbar -> Place.
4. Check N and W.
5. Check both A and B leaves.
6. Check placement using parcels from nearby floor.
7. Check closed partner and open partner behavior.
8. Damage a member before pickup and verify HP/max-HP survives replacement.
```

If this fails, instrument the first failing shared boundary. Do not add frontend-specific hacks until the common Moveables path has been ruled out.
