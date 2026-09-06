#!/usr/bin/env bash
# Reconcilie les statuts entre 🧪 Tests et 📋 Backlog, dans les deux sens.
#
# Pourquoi ce script existe : les automatisations Monday qui traversaient la
# relation entre les deux boards ont ete perdues, et le moteur d'automatisation
# ne sait pas les recreer. L'API, elle, sait lire la relation et ecrire les deux
# statuts. On reconcilie donc depuis Git, ou le jeton vit deja.
#
# Regle de precedence, pour qu'aucun aller-retour ne s'installe :
#   1. Backlog en "Retest" gagne  -> la carte de test repasse en Retest
#   2. sinon, un verdict du testeur (Teste / Bloque) descend vers le Backlog
# Un verdict ne redescend jamais vers Tests, et un Retest ne remonte jamais :
# les deux sens ne peuvent pas se declencher mutuellement.
#
# Chaque ecriture est conditionnee a un ecart reel entre les deux cotes. Sans
# ecart, rien n'est ecrit : le script peut tourner toutes les 5 minutes sans
# repolluer les cartes ni renvoyer dix fois la meme notification Slack.
set -euo pipefail

ICI=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=/dev/null
source "$ICI/monday.sh"

BOARD_TESTS=$(cfg '.monday.boards.tests')
BOARD_BACKLOG=$(cfg '.monday.boards.backlog')
COL_TEST=$(cfg '.monday.testsColumns.status')
COL_LIEN=$(cfg '.monday.testsColumns.backlogLink')
COL_BACKLOG=$(cfg '.monday.backlogColumns.status')

L_TESTE=$(cfg '.monday.statusLabels.tested')
L_BLOQUE=$(cfg '.monday.statusLabels.blocked')
L_RETEST=$(cfg '.monday.statusLabels.retest')
L_TEST_TESTE=$(cfg '.monday.testsLabels.tested')
L_TEST_BLOQUE=$(cfg '.monday.testsLabels.blocked')
L_TEST_RETEST=$(cfg '.monday.testsLabels.retest')

compte_sync=0

# --- 1. etat du board Tests : id, verdict, tache Backlog liee -----------------
REPONSE=$(monday_gql "query {
  boards(ids: $BOARD_TESTS) {
    items_page(limit: 200) {
      items {
        id
        name
        column_values(ids: [\"$COL_TEST\", \"$COL_LIEN\"]) {
          id
          text
          ... on BoardRelationValue { linked_item_ids }
        }
      }
    }
  }
}")

PAIRES=$(printf '%s' "$REPONSE" | jq -r --arg ct "$COL_TEST" --arg cl "$COL_LIEN" '
  .data.boards[0].items_page.items[]
  | . as $it
  | ($it.column_values[] | select(.id == $cl) | .linked_item_ids // []) as $liens
  | select(($liens | length) > 0)
  | [ $it.id,
      ($it.column_values[] | select(.id == $ct) | .text // ""),
      $liens[0],
      $it.name
    ] | @tsv')

if [ -z "$PAIRES" ]; then
  echo "aucune carte de test reliee a une tache du Backlog, rien a reconcilier"
  exit 0
fi

# --- 2. statut courant de chaque tache Backlog liee ---------------------------
IDS=$(printf '%s\n' "$PAIRES" | cut -f3 | paste -sd, -)
ETATS=$(monday_gql "query {
  items(ids: [$IDS]) {
    id
    column_values(ids: [\"$COL_BACKLOG\"]) { text }
  }
}")

statut_backlog() {
  printf '%s' "$ETATS" | jq -r --arg id "$1" '
    .data.items[] | select(.id == $id) | .column_values[0].text // ""'
}

# --- 3. reconciliation --------------------------------------------------------
while IFS=$'\t' read -r id_test verdict id_backlog titre; do
  [ -n "$id_test" ] || continue
  courant=$(statut_backlog "$id_backlog")
  url_backlog="https://$(cfg '.monday.account').monday.com/boards/$BOARD_BACKLOG/pulses/$id_backlog"

  # 1) Le Backlog demande un nouveau passage : la carte de test doit le refleter.
  if [ "$courant" = "$L_RETEST" ] && [ "$verdict" != "$L_TEST_RETEST" ]; then
    monday_gql "mutation { change_simple_column_value(board_id: $BOARD_TESTS, item_id: $id_test, column_id: \"$COL_TEST\", value: \"$L_TEST_RETEST\") { id } }" >/dev/null
    echo "carte de test $id_test -> $L_TEST_RETEST (le Backlog demande un retest)"
    slack_notify a-tester "$(printf '%s\n%s\n' \
      ":arrows_counterclockwise: *A retester* — $titre" \
      "💬 Discussion et historique : $url_backlog")"
    compte_sync=$((compte_sync + 1))
    continue
  fi

  # 2) Le testeur a rendu son verdict : il descend sur la tache du Backlog.
  case "$verdict" in
    "$L_TEST_TESTE")  cible="$L_TESTE";  icone=":white_check_mark:"; mot="Teste et valide" ;;
    "$L_TEST_BLOQUE") cible="$L_BLOQUE"; icone=":no_entry:";          mot="Bloque par la QA" ;;
    *) continue ;;
  esac

  if [ "$courant" = "$cible" ]; then
    continue
  fi

  monday_gql "mutation { change_simple_column_value(board_id: $BOARD_BACKLOG, item_id: $id_backlog, column_id: \"$COL_BACKLOG\", value: \"$cible\") { id } }" >/dev/null
  echo "tache $id_backlog : $courant -> $cible (verdict de la QA sur la carte $id_test)"

  monday_update "$id_backlog" "🧪 <b>$mot</b> — verdict rendu sur la carte de test.<br>Statut de la tache : $courant → $cible."
  slack_notify update-dev "$(printf '%s\n%s\n' \
    "$icone *$mot* — $titre" \
    "💬 Discussion et historique : $url_backlog")"
  compte_sync=$((compte_sync + 1))
done <<< "$PAIRES"

if [ "$compte_sync" -eq 0 ]; then
  echo "les deux boards sont deja d'accord, rien a ecrire"
else
  echo "$compte_sync statut(s) reconcilie(s)"
fi
