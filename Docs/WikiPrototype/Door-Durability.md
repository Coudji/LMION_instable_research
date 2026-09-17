# Durabilité des portes

LMION distingue les PV d'une porte déjà présente dans le monde et les PV d'une porte construite par le joueur. Les définitions peuvent fournir plusieurs valeurs de durabilité, et la construction applique ensuite le niveau de métier du personnage.

## Construction

Pour une définition qui fournit :

```lua
durability = {
    health = BASE,
    skillBaseHealth = BONUS_PAR_NIVEAU,
}
```

LMION calcule actuellement les PV maximum construits avec :

```text
PV construits = health + skillBaseHealth × niveau du métier pertinent
```

Le résultat est arrondi à l'entier inférieur et ne peut pas être négatif.

## Exemple : famille `Doors.Wood.FourPanels`

Le default actuel déclare :

```text
worldHealth     = 625
health          = 450
skillBaseHealth = 275
construction    = Woodwork 6 minimum
```

Pour une porte qui hérite de ce default sans modifier sa durabilité, la construction donne donc :

| Woodwork | PV maximum construits |
| ---: | ---: |
| 6 | 2 100 |
| 7 | 2 375 |
| 8 | 2 650 |
| 9 | 2 925 |
| 10 | 3 200 |

Le niveau 6 est le premier niveau pertinent dans cet exemple puisque la recette demande Woodwork 6.

`worldHealth` est une donnée distincte de la formule de construction. Le wiki final devra afficher clairement la valeur utilisée pour les portes présentes dans le monde et la valeur calculée pour les portes construites, sans mélanger les deux notions.

## Pickup et remplacement

La récupération d'une porte ne la remet pas à neuf. LMION transporte les PV et les PV maximum avec le colis, puis restaure cet état lors du remplacement.

Le tooltip du colis affiche simplement :

```text
Pv : actuel/max
```

Cela permet de savoir si la porte transportée était déjà endommagée avant de la replacer.

## Objectif de la page finale

À terme cette page servira de référence globale et les fiches de portes pourront afficher directement :

- PV de la porte vanilla / valeur de référence lorsque pertinente ;
- PV utilisés par LMION dans le monde ;
- PV minimum et maximum d'une construction selon le niveau de métier ;
- éventuels cas particuliers par famille de porte.
