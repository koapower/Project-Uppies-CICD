#!/bin/bash
set -e

# ───── Arguments ─────
VERSION="$1"
REPOSITORY="$2"
TOKEN="$3"

# ───── Determine Prerelease ─────
if [[ "$VERSION" == *-* ]]; then
  IS_PRERELEASE=true
else
  IS_PRERELEASE=false
fi

echo "📝 Creating GitHub release for tag: $VERSION (prerelease: $IS_PRERELEASE)"

# ───── Build Payload ─────
PAYLOAD=$(jq -n \
  --arg tag_name "$VERSION" \
  --arg name "Release $VERSION" \
  --argjson prerelease "$IS_PRERELEASE" \
  --argjson draft "false" \
  '{ tag_name: $tag_name, name: $name, draft: $draft, prerelease: $prerelease }')

# ───── Create Release ─────
RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -d "$PAYLOAD" \
  "https://api.github.com/repos/$REPOSITORY/releases")

RELEASE_ID=$(echo "$RESPONSE" | jq -r '.id // empty')

if [[ -z "$RELEASE_ID" || "$RELEASE_ID" == "null" ]]; then
  echo "❌ Failed to create release. Full response:"
  echo "$RESPONSE"
  exit 1
fi

echo "✅ Created release with ID: $RELEASE_ID"

# ───── Output to GitHub ─────
echo "release_id=$RELEASE_ID" >> "$GITHUB_OUTPUT"