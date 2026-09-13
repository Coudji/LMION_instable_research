# LargeGate open/close state preservation

Status: VALIDATED IN GAME for HP preservation on complete gates and independent A/B leaves.

## Engine behavior

Project Zomboid recreates the internal members of a vanilla-style double door while `IsoDoor:ToggleDoor()` changes between closed and open layouts. Those recreated objects do not keep the previous runtime durability automatically, which caused internal members to return to `100/100` after opening or closing.

The supplied PZ 42.20.3 JAR, Legacy and Workshop agree on the physical topology:

```text
N closed: 1=(0,0) 2=(1,0) 3=(2,0) 4=(3,0)
N open:   1=(0,0) 2=(0,1) 3=(3,1) 4=(3,0)

W closed: 1=(0,0) 2=(0,-1) 3=(0,-2) 4=(0,-3)
W open:   1=(0,0) 2=(1,0) 3=(1,-3) 4=(0,-3)
```

The V3 topology was corrected in:

```text
bd6fbac892561299999b49b7c9f3c85993a5d221  Align LargeGate layout with PZ double-door topology
```

## Failed approaches

The first V3 ports tried to preserve the complete four-member gate and also used stricter open-state parity checks than Legacy. Both approaches failed in game.

Do not reintroduce either assumption:

```text
- do not require sprite/open-state parity during the transition boundary
- do not require all four vanilla members to exist
```

A/B are independent LMION leaves and must remain valid without their partner.

## Final V3 model

Commit:

```text
8c3cdef7709f3b44a95ec7ced7ed7064fa07e398  Preserve LargeGate state per independent leaf
```

One LMION leaf is the preservation unit:

```text
leaf A -> 2 physical members
leaf B -> 2 physical members
```

The runtime observes the internal logical members 2 and 3 because either can belong to A or B depending on facing.

Flow:

```text
OnObjectAboutToBeRemoved(internal member 2 or 3)
-> resolve definition / facing / leaf / part
-> derive previous layout from corrected LargeGateTopology
-> find only the two members of that leaf
-> DoorState.capture() both

OnContainerUpdate
-> find the same leaf in the target layout
-> verify both members reached the target open/closed state
-> DoorState.restore() both
```

The partner leaf may be absent.

Ownership remains V3-compliant:

```text
DoorState          -> capture/restore semantics
DoorDurability     -> HP/maxHP semantics
LargeGateMembers   -> segment identity
LargeGateTopology  -> logical/physical geometry
LargeGateToggleState -> PZ transition timing only
```

## In-game validation

Validated by the user:

```text
damaged HP survives open/close on a complete A+B gate
A alone preserves damaged HP across open/close
B alone preserves damaged HP across open/close
no regression observed during subsequent LargeGate checks
```

This validates the HP preservation contract for the tested complete and independent-leaf cases. It is not an exhaustive validation of every family or every lock/modData field.
