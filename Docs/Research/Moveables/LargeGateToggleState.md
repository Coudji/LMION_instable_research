# LargeGate open/close state preservation

Status: IMPLEMENTED IN V3 / IN-GAME RETEST PENDING.

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

### Workshop

Workshop preserves LargeGate state across pickup/replacement through `TransportState`, but no equivalent dedicated normal `ToggleDoor()` preservation path was found.

For this issue, Legacy is therefore the behavioral oracle.

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

## Current V3 implementation

`Runtime/LargeGateToggleState.lua` was realigned with the Legacy timing model in commit:

```text
709d1ae32829a297f14b21170f50c40e20da9427  Align LargeGate toggle state preservation with Legacy
```

Current flow:

```text
OnObjectAboutToBeRemoved(logical member 2)
-> resolve LMION LargeGate segment
-> targetOpen = object:IsOpen()
-> previousState = targetOpen ? closed : open
-> compute stable gate anchor from member 2 + LargeGateTopology
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

## Validation required

Before marking this behavior validated, test at minimum:

```text
1. damage one or both internal members to non-100 values
2. open the complete LargeGate
3. verify damaged values survive
4. close it again
5. verify they still survive
```

Prefer different values on the two recreated/internal members so accidental copying is visible.

Expected debug line after a successful restore:

```text
[LMION:DEV] LargeGate toggle state restored: definition=... facing=... open=true/false
```

Do not mark this checkpoint validated until the user confirms the in-game result.
