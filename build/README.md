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

### 1a. Monday → branche + PR, par scrutation (`.github/workflows/monday-poll.yml`)

**C'est la voie retenue.** Toutes les 5 minutes, le workflow demande à Monday
les tâches du Backlog en statut `Assigné` dont la colonne `Branche` est encore
vide, et crée pour chacune la branche + la PR draft.

Le dev se sert donc lui-même, depuis Monday, en passant son item en `Assigné` —
sans qu'aucun jeton GitHub n'ait à être stocké côté Monday, sans webhook et
sans relais à héberger. C'est ce qui a fait écarter la voie « bouton +
webhook » : l'action webhook native de Monday n'autorise pas l'en-tête
`Authorization` qu'exige l'API GitHub.

Contrepartie : jusqu'à 5 minutes de latence, et les workflows planifiés de
GitHub sont souvent servis en retard aux heures chargées — compter plutôt 5 à
15 minutes en pratique. `workflow_dispatch` est activé pour déclencher un
passage immédiat au besoin.

### 1b. Monday → branche + PR, par webhook (`.github/workflows/monday-branch.yml`)

Conservé pour le jour où un déclenchement instantané est souhaité. Même script,
même résultat, mais il faut alors un PAT GitHub côté Monday.

#### Détail commun

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

Les deux voies appellent le même script, `build/scripts/create-branch.sh`, qui
crée `feat/<itemId>-slug`, écrit la spec dans `build/tasks/<itemId>.md`, ouvre
une **PR draft** portant cette même spec, puis réécrit sur l'item Monday la
branche, l'URL de la PR et le statut `En dev`.

**Le dev n'a pas à ouvrir Monday.** La spec est recopiée depuis l'item :
priorité, source, assigné, description, contexte, comportement observé et
attendu, liens utiles, visuels et maquette HTML, captures. Les champs vides
sont omis — le dev ne lit que ce qui est renseigné. L'ordre et la liste des
champs se règlent dans `metaFields` / `specFields` de la config, sans toucher
au script. Rejouable sans risque : si la branche
existe déjà, il récupère simplement la PR existante.

Le slug translittère les accents explicitement plutôt que via
`iconv //TRANSLIT`, qui en glibc rend « é » par « ? » et produisait des
branches du genre `feat/123-oc-an-secr-taire`.

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
  scripts/create-branch.sh   branche + PR draft + renvoi vers Monday
  tasks/<itemId>.md          amorce créée par l'automatisation (une par tâche)
.github/workflows/
  monday-poll.yml            scrutation Monday -> branche + PR draft
  monday-branch.yml          idem, sur webhook (voie alternative)
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

- [x] `MONDAY_API_TOKEN` et `SLACK_WEBHOOK_URL` en secrets du repo — **vérifiés sur runs réels**
- [x] ~~PAT GitHub côté Monday~~ — remplacé par la scrutation, plus rien à configurer côté Monday
- [x] ~~bouton « Créer la branche »~~ — le passage en `Assigné` suffit
- [x] canal Slack dédié : **#build-flow** (`C0BU4F46W1M`, public)
- [x] webhook Slack entrant sur #build-flow → secret `SLACK_WEBHOOK_URL`
- [ ] supprimer 2 automatisations Monday mortes (à faire dans l'UI : l'app MCP
      renvoie `USER_UNAUTHORIZED` sur `delete` comme sur `deactivate`)
      — `1718784144` « Lien github → PR » et `1718785521` « Priorité Critique
      → groupe supprimé »
- [x] `monday-branch.yml` mergé dans `main` (PR #48)
- [ ] merger `monday-poll.yml` dans `main` (sinon le `schedule` ne part pas)
- [x] nettoyer les colonnes en double du Backlog et des boîtes d'entrée

## Ménage effectué le 2 septembre 2026

**Colonnes supprimées** (toutes vérifiées vides au préalable) :

| Board | Colonne | Pourquoi |
|---|---|---|
`📋 Backlog` | `long_text_mm6rrd4d` | 2ᵉ « Description ». La 1ʳᵉ (`long_text_mm6r6v98`) est gardée **parce que l'automatisation `1718788797` la lit**. |
`📋 Backlog` | `board_relation_mm6rkvsm` | « link to Tests » avec `boardIds: []` — connectée à rien. |
`📋 Backlog` | `lookup_mm6r7zj` | miroir « Résultat QA » branché sur la relation morte ci-dessus : il n'affichait jamais rien. |
`📋 Backlog` | `board_relation_mm6rsfer` | relation vers `🐛 Liste des bugs`, board archivé. |
`🛠️ Support team & QA` | `long_text8y9j5amt` | « Description » redondante avec Contexte / Observé / Attendu. |
`🛠️ Support team & QA` | `short_textbf0vq41j` | « Lien(s) » en double de « Lien(s) utile(s) » (`linkdmxpt3fg`), qui est du bon type et **est celle que le miroir du Backlog lit**. |
`📡 Signaux produit` | `long_text_mm6rxx29` | 2ᵉ « Description ». |

**Bug corrigé** : le miroir « Résultat QA (Tests) » a été recréé
(`lookup_mm6tgc4q`) sur la **bonne** relation (`board_relation_mm6r2yf0`). Le
verdict de test de Nathan remonte maintenant dans le Backlog — ce n'était pas
le cas avant.

**Libellés remis en ordre** :
- `Source` (Backlog) : retrait de « 🔴 Critique », « 🧪 QA » et « Liste des bugs » — ce ne sont pas des sources. Reste les 3 entrées, plus Backlog direct, Roadmap / Épic et 🤖 Grafana.
- `Produit` (Fonctionnalités demandées) : retrait de « Bug ». Reste Ulysse, Ocean, Desk, Rainbow, Horizon.
- `Statut` (Support team & QA) : remis dans l'ordre du flow Slack réel, ⚙️ → 🧪 → ✅.

**Board archivé** : `🐛 Liste des bugs` (son unique item était vide). Les
remontées passent toutes par `🛠️ Support team & QA`.

## Ne pas refaire ce que Monday fait déjà

Sept automatisations tournent sur le Backlog. La plus importante pour ce flow :

> `1718788797` — Statut → `Mise en dev` **crée l'item de QA** dans `🧪 Tests`,
> groupe « À tester ».

Donc quand une PR est mergée : l'Action met `Mise en dev`, Monday crée
l'item de test pour Nathan, et l'Action poste le ping Slack. La passation est
complète et aucune des deux moitiés ne duplique l'autre. Toute évolution des
workflows doit vérifier `existingAutomations` dans la config avant d'ajouter
une étape.

## Vérification de bout en bout, 2 septembre 2026, 23h40

PR jetable `feat/3199324383-verif-secrets` → PR #49, sur l'item de test
`3199324383`. Chaque étape est un vrai run GitHub Actions, pas une simulation :

| Événement | Run | Statut Monday obtenu |
|---|---|---|
| PR ouverte | `33686265971` | `PR` ✅ |
| sortie du draft | `33686329038` | `Review` ✅ |
| PR mergée | `33686379634` | `Mise en dev` ✅ |

Le ping Slack est arrivé dans `#build-flow` à 23:40:14, avec le titre, le lien
de PR et le lien de l'item. **Les deux secrets fonctionnent.**

La PR de test a été mergée dans la branche de travail, pas dans `main`, pour
exercer le chemin `merged: true` sans déclencher les déploiements de prod.

### Panne trouvée au passage : la tâche de QA arrive orpheline

L'automatisation `1718788797` crée bien l'item dans `🧪 Tests` (vérifié :
item créé à 21:40:17, statut « À tester »), mais **la relation n'est peuplée
d'aucun des deux côtés** : `board_relation_mm6rzf4j` (côté Tests) et
`board_relation_mm6r2yf0` (côté Backlog) restent vides.

Conséquences concrètes :
- Nathan reçoit un titre nu, sans lien vers la tâche, sans description, sans PR ;
- les miroirs `Description Backlog` et `ID Backlog` du board Tests n'affichent rien ;
- le miroir `Résultat QA (Tests)` du Backlog ne peut rien remonter en retour.

**Honnêteté sur la cause** : je ne sais pas si la suppression de
`board_relation_mm6rkvsm` en est responsable. Cette colonne avait
`boardIds: []`, ce qui la faisait passer pour morte, et je l'ai supprimée
avant d'avoir jamais observé un item de QA correctement lié. La panne
pouvait donc préexister. Le correctif est le même dans les deux cas :
dans l'automatisation `1718788797`, faire pointer « connecter les tableaux »
sur le couple `board_relation_mm6r2yf0` ↔ `board_relation_mm6rzf4j`.

### Autre chose à corriger sur le board Tests

La colonne `status` porte **deux libellés pour la même chose** : « À tester »
et « A tester » (sans accent). L'automatisation écrit la version accentuée,
donc les items en « A tester » n'apparaîtront jamais dans un filtre ou une
vue basée sur le bon libellé.

### Résidu

La branche distante `feat/3199324383-verif-secrets` n'a pas pu être
supprimée : les droits git de la session autorisent la création et la mise à
jour de refs, pas leur suppression (le proxy est sain, ce n'est pas un
incident réseau). À supprimer en un clic depuis l'interface GitHub.
