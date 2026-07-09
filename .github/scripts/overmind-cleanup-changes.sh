#!/usr/bin/env bash
set -euo pipefail

# Cleanup script for stale Overmind "changes" created by repeated demo runs.
#
# `overmind changes --help` only lists list-changes, get-change,
# start-change, end-change, submit-plan, submit-signal, start-analysis, and
# get-signals - there's no delete-change. The underlying API does support
# deleting a change by UUID (changes.ChangesService/DeleteChange), it's just
# never wired up to a CLI subcommand.
#
# Rather than reimplementing auth + listing by hand, this shells out to the
# CLI itself for listing (it already knows how to authenticate, discover the
# API host, and check scopes) and only hand-rolls the one thing the CLI can't
# do: the actual delete call, via a direct Connect-protocol HTTP request (the
# same way curl can call any Connect RPC service, see https://connectrpc.com).
#
# Usage:
#   OVM_API_KEY=ovm_api_... ./overmind-cleanup-changes.sh \
#     [--title-pattern "narrow internal ingress"] [--keep 0] [--dry-run] \
#     [--app https://app.overmind.tech]
#
# --keep 0 (default) deletes every matching change - use this right before
# creating a fresh pair of demo PRs so only this run's changes remain
# afterwards. --keep N keeps the N most-recently-created matches instead.
#
# Requires: the overmind CLI, jq, curl, python3
# Requires OVM_API_KEY with the "changes:write" scope (the same scope
# already used by start-change/end-change/submit-plan).

APP="https://app.overmind.tech"
TITLE_PATTERN="narrow internal ingress"
KEEP=0
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app) APP="$2"; shift 2 ;;
    --title-pattern) TITLE_PATTERN="$2"; shift 2 ;;
    --keep) KEEP="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

: "${OVM_API_KEY:?OVM_API_KEY environment variable is required}"

echo "Listing changes via the Overmind CLI..."
CHANGES_JSON="$(overmind changes list-changes --app "$APP" --format json 2>/dev/null)"

# list-changes prints one pretty-printed JSON object per change, one after
# another (not a JSON array) - jq reads this fine as a stream of values.
MATCHES="$(jq -s --arg pattern "$TITLE_PATTERN" '
  [.[] | select(.properties.title | test($pattern; "i"))]
  | sort_by(.metadata.createdAt) | reverse
' <<<"$CHANGES_JSON")"

MATCH_COUNT="$(jq 'length' <<<"$MATCHES")"
echo "Found $MATCH_COUNT change(s) matching /$TITLE_PATTERN/i:"
# NB: .metadata.UUID here is the CLI's human-readable hyphenated UUID string
# (list-changes renders it via the SDK's ToMap(), not raw proto JSON) - it is
# NOT the base64 the raw DeleteChange call below needs. See uuid_to_base64().
jq -r '.[] | "  - \(.metadata.createdAt)  \(.properties.title)  (uuid: \(.metadata.UUID // "?"))"' <<<"$MATCHES"

TO_DELETE="$(jq -c --argjson keep "$KEEP" '.[$keep:]' <<<"$MATCHES")"
DELETE_COUNT="$(jq 'length' <<<"$TO_DELETE")"

if [[ "$DELETE_COUNT" -eq 0 ]]; then
  echo "Nothing to delete (keeping $KEEP)."
  exit 0
fi

echo "Deleting $DELETE_COUNT change(s), keeping $KEEP most-recent match(es)..."

if [[ "$DRY_RUN" != "true" ]]; then
  # The CLI never prints the token it authenticates with internally, so this
  # is the one bit of auth we have to redo ourselves for the delete call.
  # Skipped entirely in --dry-run so a dry run never needs a delete-capable
  # key, just something that can list.
  API_URL="$(curl -sf "$APP/api/public/instance-data" | jq -r '.api_url')"
  TOKEN="$(curl -sf -X POST "$API_URL/apikeys.ApiKeyService/ExchangeKeyForToken" \
    -H "Content-Type: application/json" -H "Connect-Protocol-Version: 1" \
    -d "{\"apiKey\": \"$OVM_API_KEY\"}" | jq -r '.accessToken')"

  if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
    echo "Failed to exchange OVM_API_KEY for a token" >&2
    exit 1
  fi
fi

# DeleteChangeRequest.UUID is a proto `bytes` field, so the raw Connect+JSON
# call needs it base64-encoded - convert the CLI's hyphenated string back to
# the raw 16 bytes first.
uuid_to_base64() {
  python3 -c "import sys, uuid, base64; print(base64.b64encode(uuid.UUID(sys.argv[1]).bytes).decode())" "$1"
}

FAILURES=0
RESPONSE_FILE="$(mktemp)"
trap 'rm -f "$RESPONSE_FILE"' EXIT

# Read from a process substitution rather than piping into the while loop:
# piping meant a failure in the loop body raced against jq still writing
# more output, which surfaced as a confusing "jq: broken pipe" error on top
# of whatever actually failed.
while IFS= read -r change; do
  UUID_STR="$(jq -r '.metadata.UUID' <<<"$change")"
  TITLE="$(jq -r '.properties.title' <<<"$change")"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [dry-run] would delete: $TITLE ($UUID_STR)"
    continue
  fi

  UUID_B64="$(uuid_to_base64 "$UUID_STR")"

  HTTP_STATUS="$(curl -s -o "$RESPONSE_FILE" -w '%{http_code}' -X POST "$API_URL/changes.ChangesService/DeleteChange" \
    -H "Content-Type: application/json" -H "Connect-Protocol-Version: 1" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{\"UUID\": \"$UUID_B64\"}")"

  if [[ "$HTTP_STATUS" == "200" ]]; then
    echo "  deleted: $TITLE ($UUID_STR)"
  else
    echo "  FAILED to delete: $TITLE ($UUID_STR) - HTTP $HTTP_STATUS: $(cat "$RESPONSE_FILE")" >&2
    FAILURES=$((FAILURES + 1))
  fi
done < <(jq -c '.[]' <<<"$TO_DELETE")

if [[ "$FAILURES" -gt 0 ]]; then
  echo "$FAILURES deletion(s) failed" >&2
  exit 1
fi
