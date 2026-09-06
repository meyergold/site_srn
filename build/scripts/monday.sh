#!/usr/bin/env bash
# Helpers Monday. Necessite MONDAY_API_TOKEN et jq.
# Usage : source build/scripts/monday.sh
set -euo pipefail

CFG="${CFG:-build/monday-flow.config.json}"

cfg()  { jq -r "$1" "$CFG"; }
cfgc() { jq -c "$1" "$CFG"; }

# monday_gql '<query graphql>' -> reponse JSON brute
monday_gql() {
  local query="$1"
  local payload
  payload=$(jq -n --arg q "$query" '{query: $q}')
  local out
  out=$(curl -sS -X POST https://api.monday.com/v2 \
    -H "Authorization: $MONDAY_API_TOKEN" \
    -H "Content-Type: application/json" \
    -H "API-Version: 2024-10" \
    -d "$payload")
  if echo "$out" | jq -e '.errors // .error_message' >/dev/null 2>&1; then
    echo "Erreur API Monday : $out" >&2
    return 1
  fi
  echo "$out"
}

# monday_set_status <item_id> <cle_du_label>   ex: monday_set_status 123 prOpen
monday_set_status() {
  local item_id="$1" key="$2"
  local board col label
  board=$(cfg '.monday.boards.backlog')
  col=$(cfg '.monday.backlogColumns.status')
  label=$(cfg ".monday.statusLabels.$key")
  if [ "$board" = "null" ] || [ -z "$board" ]; then
    echo "board sprint non configure dans $CFG, on saute" >&2
    return 0
  fi
  monday_gql "mutation { change_simple_column_value(board_id: $board, item_id: $item_id, column_id: \"$col\", value: \"$label\") { id } }" >/dev/null
  echo "item $item_id -> $label"
}

# monday_set_text <item_id> <cle_de_colonne> <valeur>
monday_set_text() {
  local item_id="$1" key="$2" value="$3"
  local board col
  board=$(cfg '.monday.boards.backlog')
  col=$(cfg ".monday.backlogColumns.$key")
  if [ "$board" = "null" ] || [ "$col" = "null" ]; then return 0; fi
  local escaped
  escaped=$(printf '%s' "$value" | jq -Rr '@json | .[1:-1]')
  monday_gql "mutation { change_simple_column_value(board_id: $board, item_id: $item_id, column_id: \"$col\", value: \"$escaped\") { id } }" >/dev/null
}

# monday_update <item_id> <corps>
monday_update() {
  local item_id="$1" body="$2"
  local escaped
  escaped=$(printf '%s' "$body" | jq -Rr '@json | .[1:-1]')
  monday_gql "mutation { create_update(item_id: $item_id, body: \"$escaped\") { id } }" >/dev/null
}

# item_id_from_branch <nom_de_branche> -> id ou vide
item_id_from_branch() {
  local branch="$1" prefix
  prefix=$(cfg '.git.branchPrefix')
  case "$branch" in
    "$prefix"/*) ;;
    *) return 0 ;;
  esac
  local rest="${branch#"$prefix"/}"
  local id="${rest%%-*}"
  case "$id" in
    ''|*[!0-9]*) return 0 ;;
    *) echo "$id" ;;
  esac
}

# slack_notify <texte>
# Slack repond "ok" en clair quand il a poste, un code d'erreur sinon
# (no_service, invalid_payload, channel_not_found...) mais toujours avec un
# corps de reponse court. On le lit : un webhook casse doit se voir dans le
# log, pas disparaitre en silence.
slack_notify() {
  local reponse
  if [ -z "${SLACK_WEBHOOK_URL:-}" ]; then
    echo "::warning title=Slack non configure::SLACK_WEBHOOK_URL absent, notification non envoyee"
    return 0
  fi
  reponse=$(curl -sS -X POST "$SLACK_WEBHOOK_URL" \
    -H 'Content-Type: application/json' \
    -d "$(jq -n --arg t "$1" '{text: $t}')" 2>&1) || true
  if [ "$reponse" = "ok" ]; then
    echo "Slack notifie"
  else
    echo "::warning title=Slack en echec::reponse du webhook : ${reponse:-<vide>}"
  fi
}

# monday_item_spec <item_id>
# Ecrit sur stdout la spec de la tache en markdown, a partir des champs
# listes dans metaFields / specFields de la config. Les champs vides sont
# omis, pour que le dev ne lise que ce qui est renseigne.
monday_item_spec() {
  local item_id="$1" resp
  resp=$(monday_gql "query { items(ids: [$item_id]) { name url column_values { id text ... on MirrorValue { display_value } } } }") || return 1

  printf '%s' "$resp" | jq -r \
    --argjson meta "$(cfgc '.monday.metaFields')" \
    --argjson spec "$(cfgc '.monday.specFields')" '
    .data.items[0] as $it
    | ($it.column_values
       | map({key: .id, value: ((.display_value // .text) // "")})
       | from_entries) as $v
    | [ "# " + $it.name, "" ]
      + [ ($meta[] | select(($v[.column] // "") != "") | "- **" + .title + "** : " + $v[.column]) ]
      + [ "- **Item Monday** : " + $it.url, "" ]
      + [ ($spec[]
           | select(($v[.column] // "") != "")
           | "## " + .title + "\n\n" + $v[.column] + "\n") ]
      + [ "## Critères d'\''acceptation", "", "_à compléter avec le produit si absents ci-dessus._" ]
    | join("\n")'
}
