# Modding — overrides et extensions

LMION permet de modifier une définition ou un default enregistré sans recopier son contenu complet. Le mécanisme public prévu pour cela est l'**extension**.

## Exemple simple

```lua
local LMION = require "LMION/API"

LMION.registerExtension({
    extensionId = "MyMod.BluePanelDoorBalance",

    target = {
        type = "definition",
        id = "Doors.Wood.BluePanelDoor",
    },

    patch = {
        durability = {
            health = 500,
        },
    },
})
```

L'extension ci-dessus ne remplace que `durability.health` dans la définition effective ciblée.

## Cibler un default

Une extension peut viser :

```text
target.type = "definition"
target.type = "default"
```

Modifier un default permet d'agir sur les définitions qui en héritent. L'ordre de résolution actuel est :

```text
default brut
→ extensions du default
→ définition concrète
→ extensions de la définition
```

Une valeur explicitement déclarée par la définition concrète peut donc remplacer une valeur provenant du default étendu.

## Fusion des données

Les tables de type objet/map sont fusionnées récursivement. Les listes/arrays sont remplacées comme une valeur complète.

Par exemple :

```lua
patch = {
    pickup = {
        breakChance = 10,
    },
}
```

peut modifier uniquement `pickup.breakChance`.

En revanche, remplacer une liste comme `construction.materials` revient à fournir la nouvelle liste complète :

```lua
patch = {
    construction = {
        materials = {
            { item = "Base.Plank", amount = 6 },
            { item = "Base.Nails", amount = 8 },
        },
    },
}
```

## Champs protégés

Une extension ne peut pas remplacer les champs d'identité suivants :

```text
id
defaultId
definitionId
extensionId
inherits
```

Pour changer l'identité ou l'héritage d'un objet, il faut déclarer une autre définition plutôt que détourner une extension.

## Conflits entre mods

Les extensions n'ont pas de champ `priority`. Si plusieurs addons modifient la même valeur, **l'ordre de chargement décide du dernier patch appliqué**.

Le wiki final devra insister sur ce point et documenter la méthode recommandée pour annoncer ses overrides afin de rendre les conflits entre addons compréhensibles.

## Quand utiliser quoi ?

| Besoin | Mécanisme |
| --- | --- |
| Ajouter une nouvelle porte | `registerDefinition` |
| Ajouter une nouvelle famille de valeurs réutilisable | `registerDefault` |
| Modifier une porte LMION existante | `registerExtension` sur une `definition` |
| Modifier une base partagée par plusieurs portes | `registerExtension` sur un `default` |

Le but de l'API est qu'un addon puisse modifier le contrat public sans dépendre des fichiers internes de `Services/`, `Runtime/` ou `PZ/`.
