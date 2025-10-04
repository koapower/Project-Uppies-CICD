#!/bin/bash
set -euo pipefail

VERSION="$1"
REPO="$2"
TOKEN="$3"
API_URL="https://api.github.com/repos/${REPO}/releases/tags/$VERSION"

TMPFILE=$(mktemp)
STATUS=$(curl -s -w "%{http_code}" -o "$TMPFILE" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "$API_URL")

if [ "$STATUS" -eq 200 ]; then
  RELEASE_ID=$(jq -e -r '.id // empty' "$TMPFILE" || echo "")
  if [[ -n "$RELEASE_ID" ]]; then
    echo "ℹ️  Release found for tag '$VERSION' (ID: $RELEASE_ID)"
    echo "already_exists=true" >> "$GITHUB_OUTPUT"
    echo "release_id=$RELEASE_ID" >> "$GITHUB_OUTPUT"
  else
    echo "ℹ️  Tag '$VERSION' found, but no release ID could be extracted"
    echo "already_exists=false" >> "$GITHUB_OUTPUT"
  fi
else
  echo "ℹ️  No release found for tag '$VERSION' (HTTP status: $STATUS)"
  echo "already_exists=false" >> "$GITHUB_OUTPUT"
fi

rm -f "$TMPFILE"