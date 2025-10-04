#!/bin/bash
set -e

# ───── Input ─────
BASE_VERSION="$1" # Expected format: v1.2.3

if [[ ! "$BASE_VERSION" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  >&2 echo "❌ Invalid base version: '$BASE_VERSION'"
  >&2 echo "Must be in format v1.2.3"
  exit 1
fi

# ───── Strip 'v' Prefix for Matching ─────
STRIPPED=$(echo "$BASE_VERSION" | sed 's/^v//')

# ───── Fetch all tags and match rc suffixes ─────
TAGS=$(git tag | grep "^v$STRIPPED-rc\.[0-9]\+$" || true)

if [ -z "$TAGS" ]; then
  NEXT_RC=1
else
  HIGHEST_RC=$(echo "$TAGS" | sed -E "s/^v$STRIPPED-rc\.//" | sort -n | tail -n 1)
  NEXT_RC=$((HIGHEST_RC + 1))
fi

NEXT_VERSION="v${STRIPPED}-rc.${NEXT_RC}"

echo "$NEXT_VERSION"