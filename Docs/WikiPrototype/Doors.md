# Portes

LMION traite actuellement six familles de portes. Le type est une information sémantique utilisée par le mod pour appliquer les bonnes règles de placement, de transport et de reconstruction.

| Type LMION | Usage | Frame requise | Particularité principale |
| --- | --- | --- | --- |
| `Simple` | Porte 1x1 classique | standard | placement sur une frame de porte standard |
| `Paired` | Double porte 1x1 | paired | les deux membres sont décrits par la géométrie |
| `FenceGate` | Portillon / porte de clôture | aucune | placement sans frame |
| `Sliding` | Porte coulissante | aucune | placement sans frame |
| `LargeGate` | Grand portail à deux vantaux | aucune | chaque vantail A/B contient deux membres physiques |
| `Garage` | Porte de garage | aucune | largeur variable avec chaîne START/MIDDLE/END |

## Ce que LMION conserve lors d'un déplacement

Quand une porte gérée par LMION est récupérée puis replacée, son état de durabilité transporté est conservé. Les colis utilisés par le système gardent notamment les PV et PV maximum nécessaires à la reconstruction.

Les règles exactes diffèrent selon la famille. Par exemple, un `LargeGate` est manipulé par vantail alors qu'une porte `Simple` utilise un seul colis.

## Exemple : Blue Panel Door

La porte `Doors.Wood.BluePanelDoor` est une porte vanilla prise en charge par LMION.

```text
definitionId : Doors.Wood.BluePanelDoor
entity       : Base.BluePanelDoor
hérite de    : Doors.Wood.FourPanels
type         : Simple
```

Sa définition propre décrit essentiellement son identité et sa géométrie. Les règles communes — matériau, durabilité, construction, outils de récupération et de remplacement — viennent du default `Doors.Wood.FourPanels`.

Cette séparation est volontaire : plusieurs portes visuellement différentes peuvent partager le même comportement de gameplay sans recopier les mêmes paramètres.

Voir [Durabilité des portes](Door-Durability.md) pour un exemple concret de calcul des PV construits.

## Référence complète

Le wiki final contiendra une table générée ou maintenue à partir des définitions effectives, avec au minimum :

| Porte | Origine | Type | PV monde | Construction | Métier | Matériaux | Pickup | Remplacement |
| --- | --- | --- | ---: | --- | --- | --- | --- | --- |
| Blue Panel Door | vanilla | Simple | à documenter depuis la définition effective | oui | Woodwork | voir recette | tournevis | tournevis |

Cette table n'est volontairement pas remplie ici pour tout le catalogue : le prototype sert d'abord à valider la forme du wiki avant de produire la référence exhaustive.
