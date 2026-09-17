# Modding — premiers pas

> **État du guide : prototype.** L'API publique existe, mais l'ajout complet d'une nouvelle porte depuis un addon externe n'a pas encore été validé en jeu de bout en bout. Cette page décrit donc le contrat public actuel sans prétendre remplacer le futur tutoriel testé.

## Charger l'API

Un addon externe doit passer par la façade publique :

```lua
local LMION = require "LMION/API"
```

La version publique actuelle de l'API est :

```lua
LMION.getAPIVersion() -- 1
```

## Types de portes supportés

L'API expose actuellement :

```text
Simple
Paired
FenceGate
Sliding
LargeGate
Garage
```

Ils peuvent être obtenus avec :

```lua
local types = LMION.getSupportedDoorTypes()
```

## Enregistrer une définition

Une définition possède un `definitionId` unique. Elle peut hériter d'un default LMION avec `inherits` puis ne déclarer que ce qui lui est propre.

Exemple de structure inspirée d'une porte simple actuelle :

```lua
local LMION = require "LMION/API"

LMION.registerDefinition({
    definitionId = "MyMod.Doors.ExampleDoor",
    entity = "MyMod.ExampleDoor",
    inherits = "Doors.Wood.FourPanels",

    geometry = {
        N = {
            closed = "my_tilesheet_0",
            open = "my_tilesheet_2",
        },
        W = {
            closed = "my_tilesheet_1",
            open = "my_tilesheet_3",
        },
    },
})
```

Dans cet exemple, le default fournit les paramètres communs et la définition externe fournit son identité et ses sprites.

**À valider avant publication du vrai guide :** ordre de chargement recommandé pour un addon, déclarations PZ minimales nécessaires côté scripts/entities, et procédure complète pour chaque `doorType`.

## Enregistrer plusieurs éléments

L'API permet aussi d'enregistrer un paquet de contenu :

```lua
LMION.registerContent({
    defaults = { ... },
    definitions = { ... },
    extensions = { ... },
})
```

Chaque liste est optionnelle.

## Consulter une définition effective

Pour voir la définition après héritage et extensions :

```lua
local definition = LMION.getEffectiveDefinition("Doors.Wood.BluePanelDoor")
```

L'API expose également des helpers pour retrouver une définition à partir d'une entity ou d'un objet du monde.

## Ce que le guide final devra ajouter

Le tutoriel public ne sera considéré comme terminé qu'après avoir créé un vrai addon de test externe. Il devra fournir au minimum un exemple fonctionnel pour :

- une porte `Simple` ;
- une porte `Paired` ;
- un `FenceGate` ou `Sliding` ;
- un `LargeGate` ;
- une porte `Garage` à largeur variable.

Le but est que le moddeur puisse copier un exemple minimal, remplacer ses IDs/sprites, puis comprendre précisément quels champs sont obligatoires et lesquels peuvent être hérités.
