# LargeGate open/close state preservation

Status: HP PRESERVATION VALIDATED IN GAME FOR THE RETESTED CASE.

## Problem

Project Zomboid recreates some physical members of a vanilla-style double door / LargeGate while `IsoDoor:ToggleDoor()` changes between the closed and open layouts.

For LMION LargeGate, that recreation can reset runtime state on the recreated members. The observed symptom is durability returning to `100/100` on internal members after opening and closing, even though pickup/replacement correctly preserves HP/maxHP.

This is a different lifecycle from Moveables pickup/replacement:

```text
pickup/replacement
-> LMION explicitly serializes DoorState into parcels
-> placement restores it

normal ToggleDoor
-> PZ internally removes/recreates members
-> no parcel transport exists
```

## Behavioral oracle comparison

### Legacy

Known-good Legacy contains a dedicated `LargeGateOpenState.lua` path.

Its timing contract is:

```text
Events.OnObjectAboutToBeRemoved
-> react when logical member 2 is removed
-> object:IsOpen() already represents the target state
-> object sprite/square still identify the previous physical layout
-> reconstruct the previous 4-member footprint
-> capture all four door states

Events.OnContainerUpdate
-> find the recreated gate
-> verify all 4 members reached the target open/closed state
-> restore the captured state to all four members
```

Legacy deliberately does not require the sprite-derived open state to match `object:IsOpen()` during the removal callback because PZ is in the middle of the transition at that exact boundary.

Legacy's physical layout is:

```text
N closed: 1=(0,0) 2=(1,0) 3=(2,0) 4=(3,0)
N open:   1=(0,0) 2=(0,1) 3=(3,1) 4=(3,0)

W closed: 1=(0,0) 2=(0,-1) 3=(0,-2) 4=(0,-3)
W open:   1=(0,0) 2=(1,0) 3=(1,-3) 4=(0,-3)
```

### Workshop

Workshop's `LargeGateTopology.lua` contains the same closed/open physical offsets as Legacy. Workshop preserves LargeGate state across pickup/replacement through `TransportState`, but no equivalent dedicated normal `ToggleDoor()` preservation path was found.

For the toggle-state behavior, Legacy remains the behavioral oracle. Workshop is useful here only as independent confirmation of the physical topology.

## Project Zomboid engine evidence

Inspection of `zombie.iso.objects.IsoDoor` in the supplied PZ 42.20.3 JAR confirms the same topology through the native arrays:

```text
DoubleDoorNorthClosedXOffset = [0,1,2,3]
DoubleDoorNorthClosedYOffset = [0,0,0,0]
DoubleDoorNorthOpenXOffset   = [0,0,3,3]
DoubleDoorNorthOpenYOffset   = [0,1,1,0]

DoubleDoorWestClosedXOffset  = [0,0,0,0]
DoubleDoorWestClosedYOffset  = [0,-1,-2,-3]
DoubleDoorWestOpenXOffset    = [0,1,1,0]
DoubleDoorWestOpenYOffset    = [0,0,-3,-3]
```

`IsoDoor.toggleDoubleDoor()` resolves logical members 1..4, calls its internal toggle routine on each member, then explicitly triggers `OnContainerUpdate`.

For logical members 2 and 3, the internal routine removes the old object from its square and creates a new `IsoDoor`/`IsoThumpable` on the target square. The constructor path copies only part of the old state and does not preserve health/maxHealth. Therefore the observed reset is an engine recreation effect, not a Moveables transport bug.

## V3 ownership rules

The V3 implementation must respect existing ownership boundaries:

- `DoorState` owns capture/restore semantics;
- `DoorDurability` owns effective HP/maxHP handling;
- `LargeGateProfiles` / `LargeGateMembers` own sprite/segment identity;
- `LargeGateTopology` owns logical indices and closed/open offsets;
- the toggle runtime owns only detection/timing around PZ's recreation event.

Do not duplicate durability or lock/modData semantics inside the LargeGate toggle code.

## First V3 attempt — FAILED IN GAME

The first port added an extra guard:

```lua
if segment.isOpen == targetOpen then
    return
end
```

and required old-layout members to match an expected sprite open-state during collection.

In-game result: internal members still returned to `100/100` after opening/closing.

This diverged from Legacy at the exact transition boundary. During `OnObjectAboutToBeRemoved`, `IsOpen()` may already hold the target state while the world layout still represents the previous state. The added parity checks could therefore discard the event or fail member collection.

**FAILED APPROACH / DO NOT REINTRODUCE:** use sprite/open-state parity as a prerequisite while PZ is in the middle of a LargeGate toggle transition.

## Second V3 attempt — FAILED IN GAME

`Runtime/LargeGateToggleState.lua` was then realigned with the Legacy timing model in commit:

```text
709d1ae32829a297f14b21170f50c40e20da9427  Align LargeGate toggle state preservation with Legacy
```

The user retested this implementation and confirmed that the damaged internal members still returned to `100/100`. Therefore `709d1ae...` is a tested failure and must not be recorded as a validated fix.

The timing mechanism itself matched Legacy much more closely, but it depended on `LargeGateTopology.getStateOffset()` for old-layout member collection and anchor reconstruction.

## Root cause found after the failed retest

Comparison of three independent sources revealed that V3's `LargeGateTopology.STATE_OFFSETS` had the physical axes/signs inverted relative to the engine:

```text
source                       N open Y    W closed Y     W open X/Y
Legacy                       +1          negative       +X / negative Y
Workshop                     +1          negative       +X / negative Y
PZ IsoDoor native arrays     +1          negative       +X / negative Y
V3 before correction         -1          positive       -X / positive Y
```

This was not merely a toggle-hook bug. `LargeGateTopology` is the V3 source of truth used by toggle capture, partner-state detection and placement calculations.

The topology was corrected in:

```text
bd6fbac892561299999b49b7c9f3c85993a5d221  Align LargeGate layout with PZ double-door topology
```

Current V3 physical offsets now exactly match Legacy, Workshop and the PZ JAR.

## Current toggle flow after topology correction

```text
OnObjectAboutToBeRemoved(logical member 2)
-> resolve LMION LargeGate segment
-> targetOpen = object:IsOpen()
-> previousState = targetOpen ? closed : open
-> compute stable gate anchor from member 2 + corrected LargeGateTopology
-> find old members by previous-layout square + logical index + definitionId + facing
-> DoorState.capture() all 4
-> queue pending transition

OnContainerUpdate
-> find logical member 1 at stable anchor
-> LargeGateMembers resolves the recreated 4-member gate
-> verify every member reached targetOpen
-> DoorState.restore() all 4
-> server transmit when applicable
```

The collection phase intentionally does not require sprite-derived `isOpen` parity while the transition is in progress.

## State preserved

Because the runtime delegates to `DoorState`, the intended restored state currently includes:

```text
health
effective maxHealth
logical max-health override
key id
locked state
locked-by-key state
modData
```

The toggle runtime does not define these fields itself.

## In-game validation

After the topology correction in `bd6fbac...`, the user retested the damaged LargeGate open/close path and reported that HP preservation now appears correct.

Validated for the tested case:

```text
damaged internal member HP survives normal LargeGate opening/closing
PZ's recreation of the internal members no longer resets the observed HP to 100/100
```

This validates the durability-preservation bug fix for the retested scenario. It does not by itself prove the complete N/W, all-family, lock/modData matrix.

A small LargeGate N/W replacement regression check remains worthwhile because `LargeGateTopology` is shared by placement/world-state services.
