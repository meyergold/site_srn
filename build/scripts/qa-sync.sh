#!/usr/bin/env bash
# Reconcilie les statuts entre 🧪 Tests et 📋 Backlog, dans les deux sens.
#
# Pourquoi ce script existe : les automatisations Monday qui traversaient la
# relation entre les deux boards ont ete perdues, et le moteur d'automatisation
# ne sait pas les recreer. L'API, elle, sait lire la relation et ecrire les deux
# statuts. On reconcilie donc depuis Git, ou le jeton vit deja.
#
# Arbitrage : le geste le plus recent gagne. Monday horodate chaque changement
# de statut ; on compare les deux dates et on recopie le plus recent vers
# l'autre board. Aucune priorite fixe entre les deux cotes, parce qu'une
# priorite fixe cree une boucle sans sortie : si le Backlog l'emportait
# toujours, un testeur ne pourrait jamais clore un retest qu'on lui a demande.
#
# Seuls les trois verdicts circulent : Teste, Bloque, Retest. "A tester" cote
# Tests et "Mise en dev" cote Backlog sont des etats d'arrivee, pas des
# verdicts : on n'y touche jamais.
#
# Rien n'est ecrit quand les deux cotes disent deja la meme chose. Le script
# peut donc tourner toutes les 5 minutes sans repolluer les cartes ni renvoyer
# dix fois la meme notification Slack.
set -euo pipefail

ICI=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=/dev/null
source "$ICI/monday.sh"

BOARD_TESTS=$(cfg '.monday.boards.tests')
BOARD_BACKLOG=$(cfg '.monday.boards.backlog')
COL_TEST=$(cfg '.monday.testsColumns.status')
COL_LIEN=$(cfg '.monday.testsColumns.backlogLink')
COL_BACKLOG=$(cfg '.monday.backlogColumns.status')
COMPTE=0

# Libelle -> verdict commun aux deux boards. Une chaine vide signifie
# "pas un verdict", donc rien a propager depuis ce cote.
verdict_de() {
  case "$1" in
    "$(cfg '.monday.testsLabels.tested')"|"$(cfg '.monday.statusLabels.tested')")   echo teste ;;
    "$(cfg '.monday.testsLabels.blocked')"|"$(cfg '.monday.statusLabels.blocked')") echo bloque ;;
    "$(cfg '.monday.testsLabels.retest')"|"$(cfg '.monday.statusLabels.retest')")   echo retest ;;
    *) echo "" ;;
  esac
}
libelle_test()    { case "$1" in teste) cfg '.monday.testsLabels.tested' ;; bloque) cfg '.monday.testsLabels.blocked' ;; retest) cfg '.monday.testsLabels.retest' ;; esac; }
libelle_backlog() { case "$1" in teste) cfg '.monday.statusLabels.tested' ;; bloque) cfg '.monday.statusLabels.blocked' ;; retest) cfg '.monday.statusLabels.retest' ;; esac; }

# --- etat du board Tests : verdict, date du verdict, tache liee --------------
REP_TESTS=$(monday_gql "query {
  boards(ids: $BOARD_TESTS) {
    items_page(limit: 200) {
      items {
        id name
        column_values(ids: [\"$COL_TEST\", \"$COL_LIEN\"]) {
          id text value
          ... on BoardRelationValue { linked_item_ids }
        }
      }
    }
  }
}")

PAIRES=$(printf '%s' "$REP_TESTS" | jq -r --arg ct "$COL_TEST" --arg cl "$COL_LIEN" '
  .data.boards[0].items_page.items[] | . as $it
  | ($it.column_values[] | select(.id == $cl) | .linked_item_ids // []) as $liens
  | select(($liens | length) > 0)
  | ($it.column_values[] | select(.id == $ct)) as $st
  | [ $it.id,
      ($st.text // ""),
      (($st.value // "null") | fromjson? | .changed_at // ""),
      $liens[0],
      $it.name ] | @tsv')

if [ -z "$PAIRES" ]; then
  echo "aucune carte de test reliee a une tache du Backlog, rien a reconcilier"
  exit 0
fi

# --- etat des taches Backlog liees -------------------------------------------
IDS=$(printf '%s\n' "$PAIRES" | cut -f4 | paste -sd, -)
REP_BACKLOG=$(monday_gql "query {
  items(ids: [$IDS]) { id column_values(ids: [\"$COL_BACKLOG\"]) { text value } }
}")

champ_backlog() {
  printf '%s' "$REP_BACKLOG" | jq -r --arg id "$1" --arg quoi "$2" '
    .data.items[] | select(.id == $id) | .column_values[0]
    | if $quoi == "texte" then (.text // "")
      else ((.value // "null") | fromjson? | .changed_at // "") end'
}

# --- reconciliation -----------------------------------------------------------
while IFS=$'\t' read -r id_test label_test date_test id_backlog titre; do
  [ -n "$id_test" ] || continue

  label_backlog=$(champ_backlog "$id_backlog" texte)
  date_backlog=$(champ_backlog "$id_backlog" date)
  v_test=$(verdict_de "$label_test")
  v_backlog=$(verdict_de "$label_backlog")

  # Deja d'accord, ou aucun verdict d'aucun cote : on ne touche a rien.
  [ "$v_test" = "$v_backlog" ] && continue
  [ -z "$v_test" ] && [ -z "$v_backlog" ] && continue

  # Un seul cote porte un verdict : c'est lui qui parle. Sinon, le plus recent.
  if [ -z "$v_test" ];        then sens=descend
  elif [ -z "$v_backlog" ];   then sens=monte
  elif [[ "$date_test" > "$date_backlog" ]]; then sens=monte
  else sens=descend
  fi

  url_backlog="https://$(cfg '.monday.account').monday.com/boards/$BOARD_BACKLOG/pulses/$id_backlog"

  if [ "$sens" = "descend" ]; then
    # Le Backlog est plus recent : la carte de test s'aligne.
    cible=$(libelle_test "$v_backlog")
    monday_gql "mutation { change_simple_column_value(board_id: $BOARD_TESTS, item_id: $id_test, column_id: \"$COL_TEST\", value: \"$cible\") { id } }" >/dev/null
    echo "carte de test $id_test : $label_test -> $cible (le Backlog a bouge en dernier)"
    if [ "$v_backlog" = "retest" ]; then
      slack_notify a-tester "$(printf '%s\n%s\n' \
        ":arrows_counterclockwise: *A retester* — $titre" \
        "💬 Discussion et historique : $url_backlog")"
    fi
  else
    # Le testeur a bouge en dernier : son verdict descend sur la tache.
    cible=$(libelle_backlog "$v_test")
    monday_gql "mutation { change_simple_column_value(board_id: $BOARD_BACKLOG, item_id: $id_backlog, column_id: \"$COL_BACKLOG\", value: \"$cible\") { id } }" >/dev/null
    echo "tache $id_backlog : ${label_backlog:-vide} -> $cible (verdict rendu sur la carte $id_test)"
    monday_update "$id_backlog" "🧪 <b>Verdict de la QA : $cible</b><br>Rendu sur la carte de test liee."
    case "$v_test" in
      teste)  icone=":white_check_mark:"; mot="Teste et valide" ;;
      bloque) icone=":no_entry:";         mot="Bloque par la QA" ;;
      retest) icone=":arrows_counterclockwise:"; mot="Renvoye en test" ;;
    esac
    slack_notify update-dev "$(printf '%s\n%s\n' \
      "$icone *$mot* — $titre" \
      "💬 Discussion et historique : $url_backlog")"
  fi
  COMPTE=$((COMPTE + 1))
done <<< "$PAIRES"

if [ "$COMPTE" -eq 0 ]; then
  echo "les deux boards sont deja d'accord, rien a ecrire"
else
  echo "$COMPTE statut(s) reconcilie(s)"
fi
