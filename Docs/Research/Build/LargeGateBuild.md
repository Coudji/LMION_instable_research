# LargeGate Build A/B

Status: PARTIALLY VALIDATED IN GAME.

The LargeGate Build pipeline is implemented. Frame/no-frame behavior, A/B Build availability and occupied-edge placement rejection are validated in game. The complete resource/family/orientation matrix is still not considered exhaustively validated.

## Contract

LMION exposes LargeGate construction per leaf:

```text
LargeGate
├─ leaf A -> 2 physical members
└─ leaf B -> 2 physical members
```

Each completed physical member must finish as an `IsoDoor`.

## Vanilla path kept

```text
GameEntity CraftRecipe
-> vanilla Build menu / cursor
-> SpriteConfig two-tile leaf
-> timed construction
-> ISBuildIsoEntity.setInfo
-> LMION post-build finalization
```

Vanilla remains responsible for menu/cursor/timed action/material/tool execution and initial object creation.

LMION intervenes only where the effective definition owns behavior that vanilla cannot infer from static script data.

## Engine topology rewrite

The vanilla entities:

```text
Base.DoubleDoor
Base.DoubleWireGate
Base.DoubleFenceGate
```

initially own both leaves in one four-tile SpriteConfig. At `OnGameBoot`, `Runtime/Build/VanillaLargeGateLeafPreparation.lua` verifies the expected vanilla tiles and narrows the base entity to leaf A. Leaf B uses an explicit derived GameEntity.

This is a special LargeGate engine adaptation, not a generic definition-replacement mechanism.

## Static script policy

PZ script files contain only engine-facing Build data still required at parse/load time:

```text
XUI presentation
closed SpriteConfig geometry
CraftRecipe data
```

Durability and semantic frame policy remain definition-owned.

## Frame policy — VALIDATED

Internal consequence:

```text
Simple    -> standard
Paired    -> paired
FenceGate -> none
Sliding   -> none
LargeGate -> none
Garage    -> none
```

A failed experiment attempted to inject scalar-only `dontNeedFrame` metadata into already-loaded GameEntity/SpriteConfig objects. In-game testing failed and the experiment was reverted.

Do not reintroduce that projection.

The active V3 boundary is `Hooks/Build/DoorFrameRequirement.lua`:

```text
ISBuildIsoEntity.new(...)
-> resolve effective LMION definition
-> doorType
-> DoorTypes frame requirement
-> buildObject.dontNeedFrame
```

Validated in game:

```text
framed doors still require their proper frame
FenceGate / Sliding build without a frame
Garage builds without a frame
LargeGate A and B build without a frame
```

## Unframed placement — VALIDATED

`dontNeedFrame` means that no supporting frame is required. It does not mean the target world edge may already be occupied.

`Runtime/DoorPlacement.lua` now owns the shared unframed edge rule. Placement is rejected when the same N/W edge already contains an incompatible structure such as:

```text
wall / thumpable wall
hoppable wall / fence
standard or paired door frame
window / window frame
existing door / garage door
vehicle intersection
```

FenceGate and Sliding already use this shared rule directly.

LargeGate and Garage use multi-square Build cursors, so they require the same rule at the `ISBuildIsoEntity.isValidPerSquare` boundary. Every physical Build square is checked independently.

Relevant commits:

```text
7655d41cc88aec1252ddb26f12f58e33dcd1753a  Require an empty edge for unframed door placement
9c5714a8ba5432812dcdbfbb8d1be6fb608f721a  Validate LargeGate Build edges
bac3b741d700ce2de3483a30173d0036ede547f5  Validate Garage Build edges
```

User validation confirmed:

```text
FenceGate / Sliding reject occupied wall/frame edges
LargeGate rejects overlapping wall/frame edges
Garage rejects overlapping wall/frame edges across its footprint
normal free-edge placement still works
no placement regression was observed afterward
```

Perpendicular structures meeting at one corner can still be accepted on one side and rejected on the other because PZ owns world barriers as N/W edges attached to specific squares. This is accepted behavior; LMION does not add an artificial rule forbidding corner contact.

## Post-build finalization

`Hooks/Build/DoorSetInfo.lua` is the centralized `ISBuildIsoEntity.setInfo` owner and dispatches LargeGate finalization through `LargeGateFinalizer`.

For each created tile:

```text
GameEntity -> LargeGate definition + A/B leaf
sprite -> facing + physical member
CanonicalDoor.ensure(...)
-> install closed/open geometry
-> apply definition-owned construction max health
-> final health = max health
-> square recalc / server transmit
```

## Validation status

Validated in game:

```text
frame/no-frame distinction
LargeGate A and B Build availability
occupied-edge rejection
free-edge placement
no observed regression after placement/topology fixes
```

Still not claimed as exhaustive:

```text
all LargeGate families
all resource-consumption combinations
all orientation/family combinations
all final lock/state combinations
```
