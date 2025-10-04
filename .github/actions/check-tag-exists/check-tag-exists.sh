#!/bin/bash
# -----------------------------------------------------------------------------
# Script: check-tag-exists.sh
#
# Checks if a Git tag exists in the given repository.
#
# Usage:
#   ./check-tag-exists.sh <version> <repository>
#
# Example:
#   ./check-tag-exists.sh "v1.2.3" "owner/repo"
# -----------------------------------------------------------------------------
set -euo pipefail

VERSION="$1"
REPO="$2"
API_URL="https://api.github.com/repos/${REPO}/git/refs/tags/${VERSION}"

STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" "$API_URL")

if [ "$STATUS" -eq 200 ]; then
  echo "exists=true" >> "$GITHUB_OUTPUT"
  echo "ℹ️ Tag '$VERSION' already exists."
else
  echo "exists=false" >> "$GITHUB_OUTPUT"
  echo "ℹ️ Tag '$VERSION' does not exist."
fi
