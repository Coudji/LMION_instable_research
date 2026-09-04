# V3 decision — canonical doors and large-gate construction

Status: **active V3 contract**

## Canonical world representation

LMION V3 has one gameplay package and Build is no longer optional.

Therefore there is no longer a product-level reason to preserve two persistent door backends.

**Contract:**

> Every door/opening created, finalized or reinstalled by LMION is an `IsoDoor`.

`IsoThumpable(isDoor)` may still be encountered as a vanilla/external/source representation and may need to be read or canonicalized at a narrow engine boundary, but it is never a final LMION-managed representation.

This is not a per-feature choice and must not be exposed as an option.

Consequences:

- Build always finalizes to `IsoDoor`;
- Pickup/reinstallation always finalizes to `IsoDoor`;
- future Lock/runtime code can target one canonical LMION world representation;
- helpers may recognize `IsoThumpable(isDoor)` only where compatibility with vanilla/external inputs requires it;
- no code path should decide at runtime whether LMION wants an `IsoDoor` or an `IsoThumpable` final object.

## LargeGate construction

Large gates are permanently modeled as two logical leaves:

```text
LargeGate
├─ leaf A
│  ├─ physical member 1
│  └─ physical member 2
└─ leaf B
   ├─ physical member 1
   └─ physical member 2
```

A/B is stable logical identity. Do not rename LargeGate leaves to Left/Right because screen-side left/right changes with orientation.

### V3 construction contract

Because Build is always part of LMION V3:

> Vanilla large-gate GameEntities supported by LMION no longer construct a complete A+B gate in one construction action.

They are adapted so construction exposes independent leaf A and leaf B construction.

The old V2 compatibility path:

```text
Build absent -> vanilla constructs complete gate
Build present -> construct A/B separately
```

is removed from V3. There is no "Build absent" gameplay composition anymore.

### Legacy evidence

Legacy already implements the Build-active version of this behavior in:

```text
Coudji/LMION_Legacy/
Legacy/Contents/mods/LMION_Build/42/media/lua/shared/LMION/Build/VanillaLargeGateLeafConstruction.lua
```

That implementation:

- validates the expected vanilla SpriteConfig before mutation;
- narrows the vanilla `DoubleDoor`, `DoubleWireGate` and `DoubleFenceGate` GameEntities to leaf A;
- installs separate leaf-B profiles;
- performs the SpriteConfig/GameEntity adaptation at `OnGameBoot`.

V3 should recover the validated engine behavior from Legacy, but reorganize it by V3 responsibilities instead of copying the old addon architecture wholesale.

## Architecture consequences

This decision removes several conditional branches from V3 design:

- no `isBuildEnabled()` logic for official behavior;
- no complete-gate-vs-split construction strategy switch;
- no final representation strategy switch between `IsoDoor` and `IsoThumpable`;
- LargeGate domain topology is always A/B;
- Build is a service/use case inside LMION, not a capability contributed by an optional addon.

Definitions describe what an opening is. They must not contain an option saying whether Build is installed or whether a LargeGate is split.

## Research / lifecycle constraint

LargeGate GameEntity/SpriteConfig adaptation is lifecycle-sensitive. Before implementing it in V3, consult the active engine lifecycle research and the Legacy implementation. Do not relocate the mutation to a different event merely for architectural neatness without evidence.

If V3 research proves a different lifecycle boundary is required for the current PZ build, document the evidence before changing this contract's implementation details.
