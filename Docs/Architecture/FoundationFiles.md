# V3 foundation files

This note describes the active V3 Lua foundation and its ownership boundaries. The source tree is organized by responsibility first, then by opening family where a subsystem has enough family-specific code to justify grouping.

## Foundation and public data

`LMION/Support/TableUtils.lua` owns generic table mechanics only (`deepCopy`, `deepMerge`).

`LMION/Domain/DoorTypes.lua` owns the finite semantic door vocabulary:

```text
Simple
Paired
FenceGate
Sliding
LargeGate
Garage
```

Definitions expose `doorType`; derivable implementation facts such as frame policy are not repeated as public fields.

`LMION/Definitions/Registry.lua`, `Validation.lua` and `Resolver.lua` own raw registration, structural validation and effective-definition resolution respectively.

`LMION/API.lua` is the stable addon-facing facade. External addons should use:

```lua
local LMION = require "LMION/API"
```

`Definitions/Defaults/` and `Definitions/Catalog/` are pure data. `Definitions/BuiltinContent.lua` explicitly enumerates built-in content; LMION intentionally does not discover definitions by scanning folders.

## Bootstrap

`Bootstrap/Definitions.lua` registers built-in definitions once through the public API.

`Bootstrap/Moveables.lua` installs the Moveables engine adapters and registers the tile-definition-time sprite configuration. It coordinates installation but does not own family rules.

`LMION_DEV.lua` remains a small entrypoint.

## `Services/Common`

`Services/Common` contains neutral knowledge genuinely shared by otherwise independent subsystems. It is grouped by family once a family owns several shared responsibilities:

```text
Services/Common/
├─ Garage/
│  └─ Profiles.lua
├─ LargeGate/
│  ├─ Profiles.lua
│  ├─ Members.lua
│  └─ PlacementSpace.lua
└─ SingleTileDoor/
   └─ Placement.lua
```

Responsibilities:

- `Garage/Profiles.lua` — neutral Garage definition/entity/sprite geometry index.
- `LargeGate/Profiles.lua` — neutral LargeGate definition/sprite/segment index.
- `LargeGate/Members.lua` — resolve canonical world members/leaves through native logical indices.
- `LargeGate/PlacementSpace.lua` — shared 2x2 native swing-space validation used by Build and Moveables.
- `SingleTileDoor/Placement.lua` — semantic placement dispatch for Simple, Paired, FenceGate and Sliding.

`Common` must not contain Moveables parcel/tool facts or Build workflow state.

## `LMION/Domain/GarageWidthPolicy.lua`

Responsibility: own the semantic width limits shared by Garage Build and variable Moveables placement.

For Garage, **width** means the number of tiles occupied by the START/MIDDLE*/END chain. It remains width in both N and W orientations; axis direction is an engine geometry detail, not a reason to rename the measure to length.

Current policy:

```text
MinimumWidth = 2
DefaultMaximumWidth = 6
configurable maximum = 6..12
UnlimitedGarageWidth -> no LMION cap
```

The Sandbox option is `LMION.GarageMaxWidth`.

## `Services/Build`

Build-specific code is grouped by family:

```text
Services/Build/
├─ ConstructionDurability.lua
├─ Garage/
│  ├─ Build.lua
│  ├─ FaceProxy.lua
│  ├─ Finalizer.lua
│  ├─ Requirements.lua
│  └─ WidthState.lua
├─ LargeGate/
│  ├─ BuiltPart.lua
│  ├─ Finalizer.lua
│  └─ Profile.lua
└─ SingleTileDoor/
   ├─ Finalizer.lua
   └─ Profile.lua
```

The family folder already supplies context, so filenames inside it avoid redundant prefixes such as `GarageBuildRequirements`.

Garage `WidthState.lua` owns the selected Build width, the native variable-bar input synchronization and the transient recipe modData key `LMIONGarageBuildWidth`.

Build may depend on `Domain`, narrow `PZ` adapters, runtime primitives and `Services/Common`. It must not depend on `Services/Moveables` merely to understand an opening.

## `Services/Moveables`

Moveables-specific code owns pickup/replacement transport behavior:

```text
Services/Moveables/
├─ MoveableProfileFields.lua
├─ Garage/
├─ LargeGate/
└─ SingleTileDoor/
```

These profiles enrich neutral definition information with transport-only facts such as item types, tools, skills and package weights.

Garage variable placement uses `plan.width` and the same `GarageWidthPolicy` as Build. The vanilla toolbar path remains intentionally fixed width 3.

LargeGate transport contains parcel lookup/consumption, placement planning/finalization and ghost-part selection. The former `LargeGate/WorldState.lua` partner-detection service was removed: placement no longer infers a partner and instead uses the shared swing-space rule.

## Moveables engine boundaries

`shared/LMION/Hooks/Moveables/SpriteProps.lua` owns the shared `ISMoveableSpriteProps` boundary used by single-tile doors, LargeGate and Garage. The older `SingleTileDoor.lua` name was misleading once this hook became cross-family.

Family-specific high-level hooks remain separate, for example LargeGate pickup/placement and Garage pickup/placement.

Inventory placement routing is client-side:

```text
client/LMION/Hooks/Moveables/InventoryPlacement.lua
```

It sends Garage parcels to the variable-width Garage cursor, sends single-tile/LargeGate parcels to the dedicated door inventory cursor, and delegates unknown items to vanilla.

Actual dedicated placement cursors stay in their established server realm:

```text
server/LMION/Moveables/GarageCursor.lua
server/LMION/Moveables/DoorInventoryCursor.lua
```

Multipart vanilla-cursor ghost rendering is a hook, not a cursor implementation:

```text
server/LMION/Hooks/Moveables/MultipartGhost.lua
```

No file is moved between `client`, `server` and `shared` merely for naming neatness.

## `LMION/PZ`

`PZ/` contains narrow low-level adapters around Project Zomboid objects and engine-visible identity. It must not depend upward on Build or Moveables workflows.

Workflow-specific lookups live with their owner. For example, post-Build LargeGate lookup is `Services/Build/LargeGate/BuiltPart.lua`, not a PZ helper.

## Client Build UI

Garage Build UI responsibilities remain split:

```text
client/LMION/UI/Build/GarageWidthSelector.lua
client/LMION/Hooks/Build/Garage.lua
client/LMION/Keybinds/GaragePlacement.lua
```

The UI widget owns the width selector; the hook owns vanilla UI integration; keybind registration remains independent.

## Static PZ scripts

Static scripts contain only parse-time declarations PZ actually requires: LMION transport items and custom LMION GameEntities/XUI/CraftRecipe/SpriteConfig where applicable.

**Vanilla GameEntities must not be statically redeclared by LMION.** Vanilla scripts remain the owner of vanilla entities. Supported vanilla LargeGate leaf-A adaptation is performed at the validated runtime lifecycle boundary by `Runtime/Build/VanillaLargeGateLeafPreparation.lua`; this is distinct from a conflicting static script redeclaration.

## Dependency rule

The central architectural boundary is:

```text
                 Services/Common
                /               \
             Build             Moveables
              |                    |
     family-specific code   family-specific code
```

Build and Moveables share neutral identity, geometry and placement policy only through `Services/Common`. Neither subsystem depends on the other.
