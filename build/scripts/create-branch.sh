#!/usr/bin/env bash
# Cree la branche et la PR draft d'une tache Monday, puis renvoie branche,
# PR et statut sur l'item. Idempotent : ne fait rien si la branche existe.
#
# Usage : build/scripts/create-branch.sh <item_id> <titre> [dev]
# Necessite : GH_TOKEN, et MONDAY_API_TOKEN pour le renvoi vers Monday.
set -euo pipefail
export LC_ALL=C.UTF-8

ITEM_ID="${1:-}"
TITLE="${2:-}"
DEV="${3:-}"

source "$(dirname "$0")/monday.sh"

case "$ITEM_ID" in
  ''|*[!0-9]*) echo "item_id invalide : '$ITEM_ID'" >&2; exit 1 ;;
esac
if [ -z "$TITLE" ]; then echo "titre vide pour l'item $ITEM_ID" >&2; exit 1; fi

BASE=$(cfg '.git.baseBranch')
PREFIX=$(cfg '.git.branchPrefix')
ITEM_URL="https://$(cfg '.monday.account').monday.com/boards/$(cfg '.monday.boards.backlog')/pulses/$ITEM_ID"

# Translitteration explicite : iconv //TRANSLIT en glibc rend "e" par "?",
# ce qui donnait des branches du genre feat/123-oc-an-secr-taire.
SLUG=$(printf '%s' "$TITLE" | sed \
  -e 'y/àâäáãåÀÂÄÁÃÅ/aaaaaaAAAAAA/' \
  -e 'y/çÇ/cC/' \
  -e 'y/éèêëÉÈÊË/eeeeEEEE/' \
  -e 'y/íìîïÍÌÎÏ/iiiiIIII/' \
  -e 'y/ñÑ/nN/' \
  -e 'y/óòôöõÓÒÔÖÕ/oooooOOOOO/' \
  -e 'y/úùûüÚÙÛÜ/uuuuUUUU/' \
  -e 'y/ýÿÝ/yyY/')
SLUG=$(printf '%s' "$SLUG" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' \
  | cut -c1-40 | sed -E 's/-+$//')
if [ -z "$SLUG" ]; then SLUG=tache; fi
BRANCH="$PREFIX/$ITEM_ID-$SLUG"

if git ls-remote --exit-code --heads origin "$BRANCH" >/dev/null 2>&1; then
  echo "branche $BRANCH deja presente, rien a creer"
else
  git config user.name  "github-actions[bot]"
  git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
  git fetch --quiet origin "$BASE"
  git checkout -q -b "$BRANCH" "origin/$BASE"

  mkdir -p build/tasks
  {
    printf '# %s\n\n' "$TITLE"
    printf -- '- Item Monday : %s\n' "$ITEM_URL"
    printf -- '- Dev : %s\n\n' "${DEV:-non assigné}"
    printf "## Critères d'acceptation\n\n_à reprendre depuis l'item Monday_\n"
  } > "build/tasks/$ITEM_ID.md"

  git add "build/tasks/$ITEM_ID.md"
  git commit -q -m "Amorce tâche $ITEM_ID : $TITLE"
  git push -q -u origin "$BRANCH"

  gh pr create --draft --base "$BASE" --head "$BRANCH" \
    --title "$TITLE" \
    --body "$(printf '%s\n\n%s\n\n%s\n' \
        "Item Monday : $ITEM_URL" \
        "Dev : ${DEV:-non assigné}" \
        "<!-- monday-item: $ITEM_ID -->")" >/dev/null
fi

PR_URL=$(gh pr view "$BRANCH" --json url --jq .url)

if [ -n "${MONDAY_API_TOKEN:-}" ]; then
  monday_set_text   "$ITEM_ID" branch "$BRANCH"
  monday_set_text   "$ITEM_ID" pr     "$PR_URL PR"
  monday_set_status "$ITEM_ID" inProgress
  monday_update     "$ITEM_ID" "Branche <b>$BRANCH</b> créée. PR draft : $PR_URL"
fi

echo "item $ITEM_ID -> $BRANCH -> $PR_URL"
