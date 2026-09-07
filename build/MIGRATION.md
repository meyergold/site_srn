# Brancher le flow Monday ↔ Git sur le vrai dépôt

Document de passation. À lire par la personne qui a les droits sur l'organisation
GitHub `saireninc` et sur les secrets du dépôt de production.

Tout ce qui est décrit ici a été construit et testé sur `meyergold/site_srn`, un
dépôt bac à sable. Rien n'a été poussé sur le vrai code. Cette page dit
exactement ce qu'il faut copier, ce qu'il ne faut pas copier, et comment
vérifier que ça marche.

Durée totale : **environ une heure**, dont 45 minutes de manipulations et
15 minutes de vérification sur une vraie PR.

---

## Ce que le flow fait, en une phrase

Le nom de la branche porte l'identifiant de la carte Monday
(`feat/<itemId>-slug`). À partir de là, chaque événement GitHub — PR ouverte,
commentaire, review, merge — fait avancer le statut de la carte, recopie la
discussion dans les mises à jour de la carte, et prévient le bon canal Slack.
Le verdict de la QA remonte dans l'autre sens, du board 🧪 Tests vers le
📋 Backlog.

Personne n'a besoin d'ouvrir Monday pour que Monday soit à jour, et personne
n'a besoin d'ouvrir GitHub pour lire ce qui s'est dit.

---

## Prérequis

| Ce qu'il faut | Où | Qui l'a |
|---|---|---|
| Un jeton API Monday (compte `sairen-company`, espace *Build*) | secret de dépôt `MONDAY_API_TOKEN` | Meyer |
| Deux webhooks Slack entrants, un par canal | secrets `SLACK_WEBHOOK_A_TESTER`, `SLACK_WEBHOOK_UPDATE_DEV` | Meyer |
| Droits d'admin sur l'organisation `saireninc` côté GitHub | claude.ai / GitHub | Yahya |
| Droits d'écriture sur le dépôt cible | GitHub | Yahya |

Un webhook Slack est lié à **un seul** canal : il faut donc bien deux secrets
distincts, un pour `#a-tester`, un pour `#update-dev`. Si l'un des deux manque,
le code retombe silencieusement sur `SLACK_WEBHOOK_URL` et écrit un
avertissement dans les logs — rien ne casse, mais les notifications partent
dans le mauvais canal.

**Aucun secret ne doit circuler par message, ni par ce document.** Ils se
collent directement dans *Settings → Secrets and variables → Actions* du dépôt.

---

## Étape 1 — Autoriser Claude sur l'organisation `saireninc`

Aujourd'hui la connexion GitHub de Claude ne voit que quatre dépôts personnels
(`meyergold/site_srn`, `meyergold/sairen.ressources`,
`meyergold/lucas-orange-tool`, `meyergold/agent-backend`). L'organisation
`saireninc` n'apparaît pas du tout : ce n'est pas un problème de permission fine,
elle n'est simplement pas connectée.

Deux endroits, selon qui agit :

- **Administrateur de l'organisation** : <https://claude.ai/admin-settings/claude-tag>,
  et autoriser le ou les dépôts concernés.
- **Utilisateur, pour sa propre autorisation** : claude.ai → *Réglages* →
  *Connecteurs* → reconnecter GitHub.

Vérification : une fois l'autorisation posée, le dépôt cible doit apparaître
dans la liste des dépôts disponibles d'une session Claude Code.

---

## Étape 2 — Ouvrir une nouvelle session Claude, obligatoirement

Ce point n'est pas contournable. Une session Claude Code est liée au
propriétaire des dépôts avec lesquels elle a démarré. Ajouter en cours de route
un dépôt appartenant à un autre propriétaire renvoie :

> `cross-tier adds are not supported in v1: requested "saireninc/server" but
> session already has repos from owner(s) [meyergold]. Start a new session with
> the requested repo as the initial source.`

Donc : **nouvelle session, avec le dépôt `saireninc/<dépôt>` comme source
initiale.** Ce n'est pas un problème de droits, c'est une limite de l'outil.
Inutile de chercher à ajouter le dépôt depuis la session actuelle.

---

## Étape 3 — Copier les fichiers

Neuf fichiers composent le flow. **Six se copient tels quels, trois restent.**

### Les six qui se copient

| Fichier | Rôle |
|---|---|
| `build/scripts/monday.sh` | Bibliothèque commune : appels GraphQL Monday, écriture de statut, mise à jour de carte, notification Slack |
| `build/scripts/qa-sync.sh` | Réconcilie les verdicts entre 🧪 Tests et 📋 Backlog, dans les deux sens |
| `build/monday-flow.config.json` | Le seul fichier à adapter (voir étape 5) |
| `.github/workflows/monday-sync.yml` | PR ouverte / review / merge → statut Monday + Slack |
| `.github/workflows/monday-discussion.yml` | Chaque commentaire de PR → mise à jour de la carte Monday |
| `.github/workflows/monday-qa-sync.yml` | Fait tourner `qa-sync.sh` toutes les 5 minutes |

Ces six fichiers sont en **lecture seule sur le dépôt** : ils déclarent
`permissions: contents: read`. Ils lisent des événements GitHub et écrivent dans
Monday et Slack. Ils ne poussent pas de commit, ne créent pas de branche, ne
touchent à aucun fichier du produit.

### Les trois qui restent sur le bac à sable

| Fichier | Pourquoi il ne migre pas tout de suite |
|---|---|
| `build/scripts/create-branch.sh` | Crée branche + PR draft dans le dépôt |
| `.github/workflows/monday-poll.yml` | Scrute Monday toutes les 5 min et crée les branches manquantes |
| `.github/workflows/monday-branch.yml` | Bouton Monday → `repository_dispatch` → création de branche |

Ces trois-là ont besoin de `contents: write` et `pull-requests: write` : ils
écrivent dans le dépôt. On les branche dans un second temps, une fois que la
première moitié tourne sans surprise sur le vrai dépôt. Tant qu'ils ne sont pas
migrés, les devs créent leurs branches à la main — il suffit de respecter la
convention de nommage (voir plus bas).

### Ne pas oublier

`build/scripts/*.sh` doit rester **exécutable** (`chmod +x`) : les workflows les
appellent directement. `git` conserve le bit d'exécution, mais un copier-coller
manuel via l'interface GitHub le perd.

---

## Étape 4 — Déposer les secrets

*Settings → Secrets and variables → Actions → New repository secret*, sur le
dépôt cible.

| Secret | À quoi il sert | Sans lui |
|---|---|---|
| `MONDAY_API_TOKEN` | Toutes les lectures et écritures Monday | Les workflows se sautent proprement (`if: env.MONDAY_API_TOKEN != ''`), rien ne casse, rien ne se synchronise |
| `SLACK_WEBHOOK_A_TESTER` | Poste dans `#a-tester` : ce que la QA doit prendre | Retombe sur `SLACK_WEBHOOK_URL` + avertissement dans les logs |
| `SLACK_WEBHOOK_UPDATE_DEV` | Poste dans `#update-dev` : ce que les devs doivent savoir | Idem |

`SLACK_WEBHOOK_URL` (canal de repli) est optionnel mais utile le temps que les
deux webhooks dédiés soient créés.

Aucun jeton GitHub personnel n'est nécessaire : les six fichiers migrés
utilisent le `GITHUB_TOKEN` fourni automatiquement à chaque exécution.

---

## Étape 5 — Adapter la configuration : deux lignes

Tout le mapping vit dans `build/monday-flow.config.json`. Les identifiants de
boards et de colonnes Monday sont **les mêmes** — c'est le même espace *Build*,
les mêmes boards. Seul le bloc `git` change :

```json
"git": {
  "repo": "saireninc/<dépôt>",
  "baseBranch": "main",
  "branchPrefix": "feat"
}
```

- `repo` : le dépôt cible, au format `propriétaire/nom`.
- `baseBranch` : la branche par défaut du dépôt cible. Si ce n'est pas `main`
  (`master`, `develop`…), c'est ici et nulle part ailleurs qu'on le corrige.
- `branchPrefix` : à laisser sur `feat` sauf convention interne différente ;
  il doit correspondre au préfixe réellement utilisé par les devs.

Rien d'autre à toucher.

---

## Étape 6 — Éteindre le doublon côté bac à sable

Point à ne pas rater. Les boards Monday sont partagés : si `site_srn` **et** le
vrai dépôt font tourner `monday-qa-sync.yml` toutes les 5 minutes contre les
mêmes boards, les deux réconcilient les mêmes cartes et Slack reçoit chaque
notification en double.

Une fois la migration validée, sur `meyergold/site_srn` :

- désactiver le workflow **QA ↔ Backlog** (*Actions* → le workflow → menu `…` →
  *Disable workflow*),
- et, dès que la moitié 2 sera migrée, désactiver aussi **Monday → branche
  (scrutation)**, sinon une tâche passée en « Assigné » créera une branche dans
  le bac à sable au lieu du vrai dépôt.

Un seul dépôt doit être propriétaire de la synchronisation à un instant donné.

---

## Étape 7 — Le premier test, sur une vraie PR

À faire ensemble, une fois. Prendre une carte du 📋 Backlog, noter son
identifiant (colonne *Item ID*), créer une branche nommée
`feat/<itemId>-un-slug` et ouvrir une PR.

Quatre points d'observation :

| Geste | Ce qui doit se passer | Où le voir |
|---|---|---|
| PR ouverte | statut de la carte → **PR**, une mise à jour « PR ouverte » | carte Monday |
| Un commentaire sur la PR | le commentaire est recopié dans les mises à jour de la carte, avec un lien retour vers GitHub | carte Monday |
| *Ready for review* | statut → **Review** + message dans `#update-dev` | Monday + Slack |
| Merge | statut → **Mise en dev**, création automatique de la carte de test dans 🧪 Tests, message dans `#a-tester` | Monday + Slack |

Si un point ne se produit pas, l'onglet *Actions* du dépôt donne la raison en
clair. Les deux causes de très loin les plus fréquentes :

1. **La branche ne respecte pas la convention.** Le log affiche
   `branche '<nom>' hors convention feat/<itemId>-slug, rien à recopier`. C'est
   la seule chose que les devs doivent retenir : *l'identifiant de la carte dans
   le nom de la branche.* Sans lui, aucun lien n'existe entre la PR et Monday.
2. **Le secret est absent.** Le workflow se marque en succès mais l'étape est
   sautée. Vérifier la présence de `MONDAY_API_TOKEN`.

Un troisième cas, propre aux tâches planifiées : `monday-qa-sync.yml` ne tourne
en `schedule` **que depuis la branche par défaut** du dépôt. Sur une branche de
travail, il ne se déclenche qu'à la main (*Run workflow*). Et les crons GitHub
sont au mieux approximatifs : 5 à 15 minutes de retard sont normaux, la première
exécution d'un nouveau cron ne part souvent pas du tout. En attendant, le bouton
*Run workflow* fait le même travail immédiatement.

---

## Récapitulatif

| # | Action | Qui | Durée |
|---|---|---|---|
| 1 | Autoriser Claude sur `saireninc` | Yahya | 5 min |
| 2 | Ouvrir une nouvelle session avec le dépôt cible | Yahya | 2 min |
| 3 | Copier les six fichiers | Yahya (ou Claude dans la nouvelle session) | 10 min |
| 4 | Déposer les trois secrets | Meyer | 5 min |
| 5 | Adapter les deux lignes de config | Yahya | 2 min |
| 6 | Désactiver le doublon sur `site_srn` | Meyer | 2 min |
| 7 | Premier test sur une vraie PR | ensemble | 15 min |

---

## Ce qui ne bouge pas

La question qui vient en premier, et sa réponse :

- **Aucun code produit n'est modifié.** Les seuls fichiers ajoutés vivent dans
  `.github/workflows/` et `build/`.
- **Aucune branche n'est créée par un robot** avec la première moitié : les six
  fichiers migrés sont en lecture seule sur le dépôt.
- **Aucun déploiement n'est touché.** Le flow lit des événements et écrit dans
  Monday et Slack, rien d'autre.
- **Supprimer les six fichiers suffit à tout arrêter.** Il n'y a pas de webhook
  caché, pas d'application tierce installée sur le dépôt, pas d'état conservé
  ailleurs que dans Monday.

---

## Annexe — la convention de nommage

C'est la seule règle que les développeurs ont à connaître :

```
feat/<itemId>-slug-libre
```

`<itemId>` est l'identifiant de la carte Monday, visible dans la colonne
*Item ID* du board 📋 Backlog. Exemple : `feat/3208653038-corriger-export-pdf`.

Une branche hors convention n'est pas une erreur : les workflows la constatent,
écrivent une ligne de log et s'arrêtent là. Le développement se passe
normalement, simplement Monday n'est pas mis à jour.

---

## Annexe — les statuts du Backlog, dans l'ordre

`Backlog` → `Assigné` → `En dev` → `PR` → `Review` → `Validé` →
`Mise en dev` → `Testé ✅` → `En production ✅`

Deux statuts hors de cette ligne : `Bloqué` et `Retest 🔄`, tous deux posés par
la QA depuis le board 🧪 Tests et remontés automatiquement.

Ces libellés sont écrits noir sur blanc dans `monday-flow.config.json`.
**Les renommer sur le board Monday sans les renommer dans le fichier casse la
synchronisation** — et les libellés du board Tests diffèrent volontairement de
ceux du Backlog (`Bloqué ⚠️` contre `Bloqué`), c'est `qa-sync.sh` qui fait la
correspondance.
