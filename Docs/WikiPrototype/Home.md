# LMION Wiki — prototype

> **Prototype de travail.** Cette documentation est hébergée dans le dépôt de développement pour tester la structure et le contenu d'un futur wiki public. Elle n'est pas encore la documentation officielle du mod distribué.

LMION étend la gestion des ouvertures de Project Zomboid. La version actuelle du projet se concentre sur les **portes** : construction, récupération, transport, remplacement et règles propres aux différentes familles de portes.

À terme, le wiki couvrira également les **fenêtres**, les **serrures**, les objets associés, les recettes et les autres systèmes ajoutés par LMION.

## Gameplay & référence

- [Portes](Doors.md) — familles de portes actuellement prises en charge et comportement général.
- [Durabilité des portes](Door-Durability.md) — PV dans le monde, PV de construction et influence du niveau de métier.
- **Fenêtres** — prévu, pas encore implémenté.
- **Serrures** — prévu, pas encore implémenté.
- **Objets et recettes** — sera détaillé au fur et à mesure que les systèmes seront stabilisés.

## Modding & API

- [Premiers pas](Modding-Getting-Started.md) — utiliser l'API LMION et déclarer du contenu externe.
- [Overrides et extensions](Modding-Overrides.md) — modifier proprement une définition LMION sans recopier son implémentation.

## Portes actuellement reconnues

LMION distingue six types sémantiques :

`Simple`, `Paired`, `FenceGate`, `Sliding`, `LargeGate` et `Garage`.

Le wiki final devra permettre de partir soit d'une question de joueur — « combien de PV a cette porte ? », « comment la construire ? » — soit d'une question de moddeur — « comment ajouter ma porte ? », « comment changer les PV de celle-ci ? » — sans avoir à lire la documentation interne du projet.
