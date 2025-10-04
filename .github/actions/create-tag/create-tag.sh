#!/bin/bash
# -----------------------------------------------------------------------------
# Script: create-tag.sh
#
# Creates a Git tag in the given repository pointing to the specified commit.
#
# Usage:
#   ./create-tag.sh <version> [sha]
#
# Example:
#   ./create-tag.sh "v1.2.3" (defaults to HEAD commit)
# -----------------------------------------------------------------------------

set -euo pipefail

VERSION="${1:-}"
SHA="${2:-$(git rev-parse HEAD)}"
REPO="${GITHUB_REPOSITORY:?}"

if [[ -z "${VERSION// }" ]]; then
  echo "❌ Error: version must be provided explicitly."
  exit 1
fi

echo "🧪 Creating tag '$VERSION' at commit $SHA in $REPO"

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -d @- "https://api.github.com/repos/${REPO}/git/refs" <<EOF
{
  "ref": "refs/tags/$VERSION",
  "sha": "$SHA"
}
EOF
)

BODY=$(echo "$RESPONSE" | head -n -1)
STATUS=$(echo "$RESPONSE" | tail -n1)

if [[ "$STATUS" -ne 201 ]]; then
  echo "❌ Failed to create tag. GitHub API response:"
  echo "$BODY"
  exit 1
fi

echo "✅ Created tag: $VERSION"
echo "version=$VERSION" >> "$GITHUB_OUTPUT"
