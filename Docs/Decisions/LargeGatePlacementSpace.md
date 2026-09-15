# V3 decision — LargeGate placement space

Status: **active V3 contract**

## Placement does not infer a partner

A LargeGate leaf is placed or built as an independent A/B unit. Placement code does not need to decide whether the other leaf exists, whether it is the "partner", or whether the final A+B structure is complete.

LMION supplies the correct native double-door sprites/logical indices. Project Zomboid owns the resulting double-door grouping and normal door behavior.

Consequently, placement must answer only one gameplay question:

> Can this leaf exist here and complete its native opening movement without colliding with the environment or preventing an existing LargeGate leaf from doing the same?

The removed `partnerState` / `incoherent partner` placement model must not be reintroduced.

## Native swing area

One LargeGate leaf contains two physical members. Its closed and open layouts are derived from `Domain/LargeGateTopology.lua`.

For the current native PZ double-door topology, those endpoints bound one exact 2x2 swing square. The whole square is operational space, not only the cells occupied by the final closed/open sprites.

This matters because a wall, fence, gate or door may cut through the movement path without occupying either endpoint.

`Services/Common/LargeGate/PlacementSpace.lua` owns this rule for both Build and Moveables.

## Candidate validation

A candidate LargeGate leaf is valid only when:

1. its normal closed placement passes the existing PZ/LMION placement checks for both physical members;
2. its complete 2x2 swing area contains no solid/tree/vehicle obstruction;
3. the barriers crossing the swing square do not block the movement path (`IsoGridSquare:isSomethingTo`, aligned with native double-door obstruction behavior);
4. its swing area does not overlap the swing area of any existing LMION LargeGate leaf, regardless of definition, A/B identity or orientation.

The last rule is symmetric with respect to LargeGates: a newly placed leaf may not make an already-existing LargeGate unusable.

Invalid positions still produce a red placement ghost where the frontend supports a preview; invalidity must not make the ghost disappear merely because the plan cannot be executed.

## Deliberate scope boundary

LMION does **not** reserve LargeGate swing areas globally against every construction performed later.

For example, the player may subsequently build/place a Garage, FenceGate or other object that blocks a LargeGate. This is intentional: such obstruction may be player error or a deliberate defensive arrangement.

Therefore:

```text
placing/building LargeGate -> protects its own swing + existing LargeGate swings
placing/building Garage    -> no special reverse LargeGate protection
placing/building FenceGate -> no special reverse LargeGate protection
other construction         -> no special reverse LargeGate protection
```

Do not add reverse blocking to unrelated families without a separate product decision.

## Shared ownership

The swing-space rule belongs under `Services/Common/LargeGate/` because Build and Moveables must apply the same geometry/policy without depending on one another.

Current consumers:

```text
server/LMION/Hooks/Build/LargeGate.lua
Services/Moveables/LargeGate/PlacementPlan.lua
```

Family-specific transport, parcel selection and finalization remain under `Services/Moveables/LargeGate/`. Build-specific GameEntity lookup/finalization remains under `Services/Build/LargeGate/`.
