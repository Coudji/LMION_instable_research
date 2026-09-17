# Blue Panel Door

[← Portes simples en bois](Doors-Wooden-Single.md) · [Catalogue des portes](Doors.md)

> **Emplacement image** — la fiche publique devra montrer ici la porte telle qu'elle apparaît en jeu, idéalement fermée et ouverte.

## En bref

| Caractéristique | Valeur |
| --- | --- |
| Origine | Project Zomboid vanilla |
| Catégorie | Porte simple en bois |
| Placement | Cadre de porte standard |
| Construction | Oui |
| Récupération | Oui |
| Remplacement après transport | Oui |

## Résistance

| Situation | PV maximum |
| --- | ---: |
| Porte vanilla d'origine, sans LMION | **À relever avant publication** |
| Porte présente dans le monde avec LMION | **625 PV** |
| Porte construite — Menuiserie 6 | **2100 PV** |
| Porte construite — Menuiserie 7 | **2375 PV** |
| Porte construite — Menuiserie 8 | **2650 PV** |
| Porte construite — Menuiserie 9 | **2925 PV** |
| Porte construite — Menuiserie 10 | **3200 PV** |

Pour cette porte, la résistance d'une construction suit actuellement :

`450 + 275 × niveau de Menuiserie`

La construction demande au minimum **Menuiserie 6**, d'où le début du tableau au niveau 6.

## Construction

**Compétence requise :** Menuiserie 6

**Outils :**
- marteau ;
- tournevis.

**Matériaux :**
- 4 planches ;
- 4 clous ;
- 2 charnières ;
- 4 vis ;
- 1 poignée de porte.

**XP :** 35

## Récupération et transport

Pour retirer cette porte du monde :

- **Menuiserie 3** minimum ;
- **tournevis** requis ;
- la définition actuelle ne lui applique **aucun risque de casse** lors de la récupération ;
- le colis obtenu pèse **17**.

Les PV actuels et les PV maximum de la porte sont conservés dans le colis afin d'être restaurés lorsqu'elle est replacée.

## Replacer la porte

- **Tournevis** requis ;
- la porte doit être replacée sur un **cadre de porte standard** ;
- son état de durabilité transporté est restauré.

## Remarques

Cette fiche est volontairement pensée comme une page de **gameplay**, pas comme une page de définition Lua. Un joueur doit pouvoir y trouver tout ce qui concerne ce modèle sans connaître l'architecture interne de LMION.

Les identifiants techniques et les exemples de code appartiendront à la partie [Modding](Modding-Getting-Started.md), pas au corps principal de cette fiche.