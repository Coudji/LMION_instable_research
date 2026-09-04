# LMION unstable research

This repository is the active **LMION V3 development/research workspace**.

It is intentionally allowed to contain experimental commits, failed branches, instrumentation and migration work. It is **not** the final clean public-history repository.

Once LMION V3 reaches a stable/release-quality state, the validated source can be transferred/squashed into the separate clean LMION repository prepared for the actual mod.

## Repository roles

- `Coudji/LMION_instable_research` — active V3 development, research, experiments and validation.
- `Coudji/LMION_Legacy` — V1/V2 archaeology, behavioral oracle and historical research source.
- final clean LMION repository — release-quality history only; do not target it during unstable development.

## Read this first

The canonical resumable development state is [`CURRENT_STATE.md`](CURRENT_STATE.md).

Before changing a Project Zomboid integration point that has already been researched, consult the relevant material under `Docs/Research/` and, when necessary, the original source in `LMION_Legacy/Legacy/Research`.

## Product direction

LMION V3 is one gameplay mod with all official gameplay systems loaded together. Internal source remains modular and responsibility-oriented.

The public addon boundary remains intentionally small and stable. Third-party mods should ultimately consume a public facade such as:

```lua
local LMION = require "LMION/API"
```

Internal implementation paths are not public contracts.
