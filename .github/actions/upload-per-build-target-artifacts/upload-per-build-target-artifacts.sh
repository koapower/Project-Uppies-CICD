#!/bin/bash
set -e

# ───── Arguments ─────
PROJECT="$1"
VERSION="$2"
RELEASE_ID="$3"
REPO="$4"
TOKEN="$5"
BUILD_TARGETS_JSON="$6"

# ───── Parse Build Targets ─────
BUILD_TARGETS=$(echo "$BUILD_TARGETS_JSON" | jq -r '.[]')

for PLATFORM in $BUILD_TARGETS; do
  ARTIFACT_PATH="${PROJECT}-${VERSION}-${PLATFORM}"
  ZIP_NAME="${ARTIFACT_PATH}.zip"

  if [ -d "$ARTIFACT_PATH" ]; then
    echo "📦 Zipping contents of $ARTIFACT_PATH → $ZIP_NAME"
    (cd "$ARTIFACT_PATH" && zip -r "../$ZIP_NAME" .)

    echo "📤 Uploading $ZIP_NAME to Release ID: $RELEASE_ID"

    HTTP_CODE=$(curl -s -w "%{http_code}" -o /tmp/upload_response.json -X POST \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/zip" \
      --data-binary @"$ZIP_NAME" \
      "https://uploads.github.com/repos/$REPO/releases/$RELEASE_ID/assets?name=$ZIP_NAME")

    if [ "$HTTP_CODE" -ne 201 ]; then
      echo "❌ Upload failed for $ZIP_NAME (HTTP $HTTP_CODE)"

      ERRORS=$(jq -r '.errors[]?.message // .errors[]? // empty' /tmp/upload_response.json)
      if [[ -n "$ERRORS" ]]; then
        echo ""
        echo "🚫 Error(s):"
        echo "$ERRORS"
      fi

      exit 1
    else
      echo "✅ Uploaded $ZIP_NAME"
    fi
  else
    echo "⚠️ Skipping: $ARTIFACT_PATH not found"
  fi
done
