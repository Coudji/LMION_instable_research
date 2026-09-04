# LMION V3 catalog data

Status: **active V3 architecture**

This document explains the data-only part of LMION's opening registry. It does not describe Pickup, Build, world-object lookup or placement runtime.

## `Definitions/Defaults/`

A default is a reusable block of opening data identified by `defaultId`.

It contains values shared by several concrete definitions, for example:

- semantic `doorType`;
- materials and sounds;
- durability;
- construction requirements;
- pickup/replacement requirements.

A default does not identify one exact vanilla opening and does not register itself. It is pure data consumed through the public registration API.

Example relationship:

```text
Doors.Wood.FourPanels
        ↑
        └── Doors.Wood.WhitePanelDoor
```

## `Definitions/Catalog/`

A catalog file describes one exact supported opening.

Its main responsibilities are:

- stable `definitionId`;
- vanilla GameEntity identity through `entity` or `entities`;
- optional inheritance from one `defaultId`;
- exact geometry for the opening;
- only the per-opening overrides that differ from the inherited default.

Catalog files are data, not executable gameplay services. They must not search the world, create `IsoDoor`, install hooks or make placement decisions.

## `Definitions/BuiltinContent.lua`

`BuiltinContent.lua` is the explicit list of data shipped by LMION itself.

It has no directory scanning and no gameplay behavior. Its sole purpose is to define which defaults and definitions are registered during bootstrap.

Explicit registration makes the built-in dataset deterministic and keeps missing/extra content visible in code review.

## `doorType` and frame requirements

`doorType` is the public semantic fact. The current finite vocabulary is:

```text
Simple
Paired
FenceGate
Sliding
LargeGate
Garage
```

Frame requirements are internal consequences owned by `Domain/DoorTypes.lua`:

```text
Simple    -> standard
Paired    -> paired
FenceGate -> none
Sliding   -> none
LargeGate -> none
Garage    -> none
```

The old V2 public `frame` field is therefore not carried into V3 definitions/defaults when it only repeats the meaning of `doorType`.

A standalone definition that does not inherit a default must state its `doorType` explicitly.

## Family geometry

Geometry describes facts that runtime cannot safely invent.

### Simple / FenceGate / Sliding

Exact N/W closed/open sprites:

```lua
geometry = {
    N = { closed = "...", open = "..." },
    W = { closed = "...", open = "..." },
}
```

### Paired

Paired doors keep stable `left` / `right` member identity because that vocabulary is meaningful for this 1x1 paired family:

```lua
entities = {
    left = "...",
    right = "...",
}
```

Geometry explicitly describes both members for N and W. There is no separate topology flag: `doorType = "Paired"`, member identities and geometry already contain the necessary semantic facts.

### Garage

Garage geometry explicitly uses `START`, `MIDDLE`, `END` roles for both orientations.

The old V2 `topology = { type = "garage" }` field is not needed in V3. `doorType = "Garage"` supplies the semantic type, while the geometry supplies the physical roles.

### LargeGate

LargeGate geometry explicitly contains logical leaf `A` and leaf `B`, each with its physical members for N and W.

A/B is stable logical identity. It must not be replaced with Left/Right.

There is no public topology strategy flag. `doorType = "LargeGate"` plus explicit A/B geometry describes what the opening is; construction/placement consequences remain internal runtime responsibilities.

## Current built-in dataset

The V3 catalog migration currently registers:

```text
23 defaults
72 concrete definitions
```

Definitions by family:

```text
Doors/Paired          5
Doors/Single/Metal   16
Doors/Single/Wooden  27
FenceGates            9
GarageDoors           7
LargeGates            6
SlidingDoors          2
                     --
Total                 72
```

This migration is data-only. Counts prove what `BuiltinContent.lua` intends to register; they do not by themselves validate GameEntity availability or gameplay behavior in Project Zomboid.
