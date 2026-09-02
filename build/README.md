# Flow produit ↔ dev — v1 (bac à sable)

Objectif : que **personne n'ait à mettre à jour Monday à la main**. Les devs vivent
dans Git, tout le reste de l'équipe vit dans Monday et Slack, et la synchro est
automatique.

Repo de test : `meyergold/site_srn`. Espace Monday : **Build** (`7494912`).

> ⚠️ Bac à sable. Un push sur `main` de ce repo déclenche GitHub Pages **et**
> Vercel en production. Les branches créées par l'automatisation ne déclenchent
> aucun déploiement — ne merger dans `main` que volontairement.

## L'architecture Monday (existante)

Espace **Build** (`7494912`). Quatre boîtes d'entrée alimentent un board de
travail unique, qui alimente le pilotage :

```
🛠️ Support team & QA  ┐
✨ Fonctionnalités     ├──►  📋 Backlog  ──►  ⚡ Sprints  ──►  🎯 Épics  ──►  🗺️ Product Roadmap
🐛 Liste des bugs      │     (le board de          │
📡 Signaux produit     ┘      travail)             └──►  🧪 Tests
```

`📋 Backlog` (`5103238969`) est **le** board sur lequel branche la synchro Git.
Il porte déjà les colonnes `Source — …` et les miroirs qui remontent contexte,
comportement observé/attendu et captures depuis les boîtes d'entrée : une tâche
arrive avec son contexte, sans recopie.

`⚡ Sprints` n'est pas un board de tâches — c'est un item par sprint (timeline,
objectifs, actif). Les tâches du Backlog s'y rattachent.

## Les statuts

Les 8 statuts vivent sur la colonne `Statut` du board Backlog
(`color_mm6rnz2n`). **Seuls 3 sont bougés à la main** :

| Statut | Qui / quoi le déclenche |
|---|---|
| `Backlog` | dépôt initial (boîte d'entrée, ou toi) |
| `Assigné` | **manuel** — toi + Yahya, le lundi |
| `En dev` | auto — le dev clique « Créer la branche » sur l'item |
| `PR` | auto — ouverture de la PR (draft incluse) |
| `Review` | auto — la PR sort du draft |
| `Validé` | auto — review approuvée |
| `Mise en dev` | auto — merge de la PR (+ ping Slack pour la QA) |
| `Testé ✅` | **manuel** — Nathan Berracasa |
| `En production ✅` | **manuel** — Yahya |

`Bloqué` et `Retest 🔄` restent manuels, hors du flow automatique.

Deux colonnes ont été ajoutées au Backlog pour la synchro, à ne pas remplir à
la main : **`Branche`** (`text_mm6trh7`) et **`PR GitHub`** (`link_mm6tvy5a`).

## Les deux automatisations

### 1. Monday → branche + PR (`.github/workflows/monday-branch.yml`)

Le dev clique un bouton sur son item Monday. Monday appelle :

```
POST https://api.github.com/repos/meyergold/site_srn/dispatches
Authorization: Bearer <PAT GitHub, scope repo>
Accept: application/vnd.github+json

{
  "event_type": "monday-create-branch",
  "client_payload": { "item_id": "123456789", "title": "Titre de l'item", "dev": "Prénom" }
}
```

Le workflow crée `feat/<itemId>-slug`, amorce `build/tasks/<itemId>.md` avec le
lien de l'item, ouvre une **PR draft**, puis réécrit sur l'item Monday la
branche, l'URL de la PR et le statut `En cours`. Rejouable sans risque : si la
branche existe déjà, il récupère simplement la PR existante.

### 2. Git → Monday (`.github/workflows/monday-sync.yml`)

L'id de l'item est lu dans le nom de la branche (`feat/<itemId>-slug`) — c'est
tout le couplage, il n'y a pas de base de correspondance à maintenir. Une
branche hors convention est simplement ignorée.

| Événement GitHub | Effet |
|---|---|
| PR ouverte / réouverte | statut `PR` + update sur l'item |
| PR sortie du draft | statut `Review` + update |
| review `approved` | statut `Validé` + update |
| PR mergée | statut `Mise en dev` + update + **ping Slack « à tester »** |
| PR fermée sans merge | update seulement, pas de changement de statut |

## Configuration

Tout le mapping vit dans **`monday-flow.config.json`** — board ids, colonnes,
libellés de statut, produits, préfixe de branche, canal Slack. C'est le seul fichier à
toucher pour brancher le flow sur le vrai repo de Yahya en v2 : aucun id n'est
codé en dur dans les workflows.

Les libellés du JSON doivent correspondre **exactement** à ceux du board. Un
libellé inconnu fait échouer le run avec la liste des valeurs valides, plutôt
que de créer silencieusement un doublon sur le board.

## Secrets à créer sur le repo

`Settings → Secrets and variables → Actions → New repository secret`

| Secret | À quoi ça sert | Où le générer |
|---|---|---|
| `MONDAY_API_TOKEN` | écrire statut / colonnes / updates sur les items | Monday → avatar → Développeurs → Mes jetons d'accès |
| `SLACK_WEBHOOK_URL` | poster le « à tester en dev » dans le canal dédié | Slack → app Incoming Webhooks → canal choisi |

Côté Monday il faut en plus un **PAT GitHub** (scope `repo`) stocké dans
l'intégration/webhook Monday pour appeler `/dispatches`.

Les deux workflows dégradent proprement : sans `MONDAY_API_TOKEN` ils ne
plantent pas, ils sautent l'étape de synchro.

## Avant le premier test

`repository_dispatch` ne se déclenche que si le workflow est présent sur la
**branche par défaut**. Les événements `pull_request` fonctionnent en revanche
depuis la branche de la PR. Donc :

- `monday-sync.yml` est testable dès cette branche ;
- `monday-branch.yml` doit être mergé dans `main` pour être déclenchable.

## Fichiers

```
build/
  README.md                  ce document
  monday-flow.config.json    tout le mapping Monday <-> Git
  scripts/monday.sh          appels API Monday + parsing de branche + Slack
  tasks/<itemId>.md          amorce créée par l'automatisation (une par tâche)
.github/workflows/
  monday-branch.yml          Monday -> branche + PR draft
  monday-sync.yml            Git -> Monday
```

## Vérifié en réel le 2 septembre 2026

Sur l'item jetable `3199324383` du Backlog, via l'API Monday, avec exactement
les mutations que les workflows exécutent :

- les 8 transitions de statut passent, **emoji compris** (`Testé ✅`,
  `En production ✅`) ;
- `Branche` et `PR GitHub` s'écrivent et se relisent correctement ;
- `create_update` poste bien l'update sur l'item ;
- un libellé erroné échoue avec `ColumnValueException / missingLabel` et la
  liste des statuts valides — le run casse au lieu de polluer le board ;
- l'item a été remis à `Backlog` et ses deux colonnes vidées.

## Reste à faire

- [ ] `MONDAY_API_TOKEN` et `SLACK_WEBHOOK_URL` en secrets du repo
- [ ] PAT GitHub (scope `repo`) côté Monday, pour appeler `/dispatches`
- [ ] bouton « Créer la branche » sur le board Backlog, câblé sur le webhook
- [ ] canal Slack dédié + son webhook, puis renseigner `slack.flowChannel`
- [ ] merger `monday-branch.yml` dans `main` (sinon `repository_dispatch` ne part pas)
- [ ] nettoyer les colonnes en double du Backlog et des boîtes d'entrée
