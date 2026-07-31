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

- [ ] **Vidéo complète** — la démo santé déjà tournée. À publier sur YouTube
      en non répertorié, puis me donner l'URL : je remplace l'image par
      l'embed maison.
- [ ] `images/rainbow/dicter-un-workflow-1.png` — vue d'ensemble : la demande
      en langage naturel et Ulysse en train de construire. *(Remplacé par
      l'embed vidéo si la vidéo arrive.)*
- [ ] `images/rainbow/dicter-un-workflow-2.png` — la question de cadrage
      « sur quel logiciel ? » avec les choix Doctolib / Enovacom / EDL.
- [ ] `images/rainbow/dicter-un-workflow-3.png` — le workflow généré, canvas
      entier lisible.

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
- [ ] `images/sante/parcours-patient-5.png` — l'écran de choix du canal SMS.

## Lot 3 — Ulysse

Page : `/produit/ulysse`

- [ ] `images/produit/ulysse-comparaison-modeles.png` — les propositions de
      plusieurs IA côte à côte sur une même demande.

## Lot 4 — Workflows et labels (emplacements déjà en attente)

Ces emplacements existent depuis la création des pages et sont **vides**.
La démo santé ne les couvre pas : ils demandent un second screencast.

Page `/rainbow/creer-un-workflow` :

- [ ] `images/rainbow/creer-un-workflow-1.png` — vue d'ensemble de l'éditeur.
- [ ] `images/rainbow/creer-un-workflow-2.png` — le choix du déclencheur.

Page `/rainbow/classifier-une-tache` :

- [ ] `images/rainbow/classifier-une-tache-1.png` — le nœud dans un workflow.

Pages `/labels/*` :

- [ ] `images/labels/groupes-et-colonnes-1.png` — menu « Gérer les colonnes ».
- [ ] `images/labels/groupes-et-colonnes-2.png` — choix des groupes pour une
      colonne personnalisée.
- [ ] `images/labels/classification-1.png` — la consigne de classification
      d'un groupe.
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
