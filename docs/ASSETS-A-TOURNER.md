# Fiche de tournage — assets docs.sairen.io

Fichier de travail interne (non publié : il n'est pas dans `docs.json`).
Chaque emplacement listé ici est **déjà câblé dans les pages** : dès qu'un
fichier est déposé au chemin exact, il s'affiche sans autre modification.

## Réglages Screen Studio, une fois pour toutes

| Réglage | Valeur |
|---|---|
| Résolution d'export | 1920 × 1080 (ou 2× la zone capturée) |
| Format des boucles | **MP4 H.264**, sans audio — 5× plus léger qu'un GIF |
| Format des fixes | **PNG** |
| Durée d'une boucle | 4 à 8 s, geste unique, début et fin sur le même écran |
| Poids cible | boucle ≤ 1,5 Mo · PNG ≤ 400 Ko |
| Curseur | visible, taille par défaut, sans clic sonore |
| Zoom auto | doux, un seul zoom par boucle |
| Fond / cadre | pas de bureau visible, pas de barre de navigateur |

**Anonymisation obligatoire** sur toutes les captures santé : aucun nom,
numéro de téléphone, date de naissance ou motif réels. Utilisez un jeu de
données fictif (« Martin Dupont », `+33 6 00 00 00 00`).

Les boucles MP4 sont acceptées : je les intègre avec un lecteur en autoplay
muet. Si vous préférez le GIF, respectez le poids cible — le GIF existant
`ocean-labeliser.gif` pèse 7,2 Mo, à ne pas reproduire.

---

## Lot 1 — Dicter un workflow (priorité haute)

Page : `/rainbow/dicter-un-workflow`

- [x] **Vidéo complète** — « Ulysse - Build a labeling workflow » intégrée
      (`fZdHuwpjrd4`). Elle remplace l'emplacement image n° 1.
- [x] `images/rainbow/dicter-un-workflow-2.png` — la question de cadrage
      « Quel canal SMS utiliser pour ce workflow ? ». **Reçue.**
- [x] `images/rainbow/dicter-un-workflow-3.png` — le workflow généré.
      **Reçue**, recadrée pour retirer le vide du bas. Sert aussi de vue
      d'ensemble sur `creer-un-workflow-1.png`.
- [ ] **À refaire si possible** : la même capture en disposition
      **Verticale** (le bouton en haut du canvas). En horizontal, le workflow
      s'étale sur 2 460 px et les titres de nœuds sont tronqués — à la largeur
      d'une page de doc, ils deviennent illisibles. En vertical, l'image est
      haute et étroite : chaque nœud reste lisible.

## Lot 2 — Parcours patient (priorité haute)

Page : `/integrations/health/parcours-patient`

- [ ] `images/sante/parcours-patient-1.png` — canvas du rappel J-2 / J-1 avec
      reprogrammation et liste d'attente.
- [ ] `images/sante/parcours-patient-2.png` — canvas de l'appel non abouti :
      contact → SMS → qualification du motif → les trois orientations.
- [ ] `images/sante/parcours-patient-3.png` — canvas du suivi J+1 / J+7 avec
      l'analyse de réponse et l'alerte soignant.
- [ ] `images/sante/parcours-patient-4.png` — canvas satisfaction : RDV
      terminé → satisfaction → avis + prise en charge.
- [x] `images/sante/parcours-patient-5.png` — l'écran de choix du canal SMS.
      **Reçue** (même capture que `dicter-un-workflow-2.png`).
- [x] `images/sante/parcours-patient-agenda.png` — « D'où viennent tes
      rendez-vous ? » avec Doctolib / Enovacom (XploreRVE) / EDL (XploreRVE) /
      CSV / autre système. **Reçue** — elle a servi à documenter la liste
      exacte des sources dans la page.
- [x] **Vidéo complète** — « Le patient autonome » intégrée (`XOGF3zfXQ6o`).

## Lot 3 — Ulysse

Page : `/produit/ulysse`

- [x] `images/produit/ulysse-comparaison-modeles.png` — les réponses de deux
      IA côte à côte, avec le sélecteur et la conso moyenne. **Reçue**,
      recadrée. Elle a servi à documenter le geste complet (sélection →
      envoi unique → « Choisir cette réponse »).

## Lot 4 — Workflows et labels (emplacements déjà en attente)

Ces emplacements existent depuis la création des pages et sont **vides**.
La démo santé ne les couvre pas : ils demandent un second screencast.

Page `/rainbow/creer-un-workflow` :

- [ ] `images/rainbow/creer-un-workflow-1.png` — vue d'ensemble de l'éditeur.
- [x] `images/rainbow/creer-un-workflow-2.mp4` + `.png` (image d'attente) —
      le choix du déclencheur. **Reçu** en GIF de 12,2 Mo, converti en MP4
      de 539 Ko (÷23) et recadré sur la fenêtre de l'app. La liste réelle
      des déclencheurs qu'il montre est désormais documentée en tableau.
- [ ] **À refaire proprement** : l'enregistrement vient de l'entité
      **CCE - DEV** et la liste de labels affiche des noms de test
      (« testt emna 4 », « yahya », « test label »…). Lisible, mais peu
      présentable sur une doc publique. Une reprise sur une entité propre,
      avec des labels plausibles (Urgent / Normale / Basse), serait mieux.

Page `/rainbow/classifier-une-tache` :

- [x] `images/rainbow/classifier-une-tache-1.png` — le nœud dans un workflow
      (disposition **verticale**, bien plus lisible). **Reçue.**
- [x] `images/rainbow/classifier-une-tache-2.png` — le panneau de
      configuration du nœud. **Reçue** (découpée de la même capture). Elle a
      corrigé une erreur de la doc : le nœud porte sa propre consigne, en
      plus de celle de chaque groupe.

Pages `/labels/*` :

- [x] `images/labels/groupes-et-colonnes-1.png` — la fenêtre « Gérer les
      colonnes ». **Reçue**, recadrée sur le modal. Elle a permis de
      documenter les poignées, l'œil, « Obligatoire » et « Trier par ».
- [ ] `images/labels/groupes-et-colonnes-2.png` — choix des groupes pour une
      colonne personnalisée.
- [x] `images/labels/classification-1.png` — l'éditeur de groupe avec la
      description et la consigne. **Reçue**, recadrée sur le modal. Elle a
      appris à la doc : limite de 120 caractères sur la description, bouton
      **Régénérer** la consigne, type de labels et visibilité au niveau du
      groupe.
- [ ] `images/labels/options-classification-1.png` — les trois options du
      groupe.
- [ ] `images/labels/introduction-1.png` — schéma définir → classifier →
      afficher. **Pas besoin de le tourner** : je peux le dessiner en SVG aux
      couleurs Sairen, dites-le moi.

---

## Comment me livrer les fichiers

Déposez-les aux chemins exacts sous `docs/images/…` et poussez, ou dites-moi
où vous les avez mis. Les dossiers `images/sante/` et `images/produit/`
n'existent pas encore : ils se créent au premier fichier.

Un média collé dans une conversation n'atteint pas le disque de la session —
il faut passer par le repo ou une URL téléchargeable.
