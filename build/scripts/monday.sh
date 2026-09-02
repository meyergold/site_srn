#!/usr/bin/env bash
# Helpers Monday. Necessite MONDAY_API_TOKEN et jq.
# Usage : source build/scripts/monday.sh
set -euo pipefail

CFG="${CFG:-build/monday-flow.config.json}"

cfg() { jq -r "$1" "$CFG"; }

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
slack_notify() {
  [ -n "${SLACK_WEBHOOK_URL:-}" ] || return 0
  curl -sS -X POST "$SLACK_WEBHOOK_URL" \
    -H 'Content-Type: application/json' \
    -d "$(jq -n --arg t "$1" '{text: $t}')" >/dev/null
}
