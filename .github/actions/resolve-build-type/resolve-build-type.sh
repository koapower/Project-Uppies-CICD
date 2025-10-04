#!/bin/bash
set -euo pipefail

# ───── Input Parameters ─────
REF="$1"
EVENT="$2"
TESTS_ONLY="$3"
BUILD_TYPE_OVERRIDE="$4"

BUILD_TYPE="preview"

echo "🔍 Starting build type resolution..."

# 1️⃣ Tests-only override forces preview
if [[ "${TESTS_ONLY}" == "true" ]]; then
  BUILD_TYPE="preview"
  echo "✅ Tests-only override detected → forcing buildType=preview"

# 2️⃣ Manual override (if valid)
elif [[ -n "${BUILD_TYPE_OVERRIDE}" ]]; then
  if [[ "${BUILD_TYPE_OVERRIDE}" =~ ^(preview|release_candidate|release)$ ]]; then
    BUILD_TYPE="${BUILD_TYPE_OVERRIDE}"
    echo "✅ Manual buildType override detected → buildType=${BUILD_TYPE}"
  else
    echo "⚠️ Invalid buildType override provided: '${BUILD_TYPE_OVERRIDE}' — ignoring"
  fi

# 3️⃣ Auto-detect from event and ref
else
  case "${EVENT}" in
    pull_request)
      BUILD_TYPE="preview"
      echo "📦 Pull request event → buildType=preview"
      ;;
    push)
      if [[ "${REF}" =~ ^refs/tags/v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        BUILD_TYPE="release"
        echo "🏷️ Release tag detected → buildType=release"
      elif [[ "${REF}" =~ ^refs/tags/v[0-9]+\.[0-9]+\.[0-9]+-rc\.[0-9]+$ ]]; then
        BUILD_TYPE="release_candidate"
        echo "🏷️ Release candidate tag detected → buildType=release_candidate"
      else
        BUILD_TYPE="preview"
        echo "📦 Regular push → defaulting to buildType=preview"
      fi
      ;;
    *)
      BUILD_TYPE="preview"
      echo "📦 Other event (${EVENT}) → defaulting to buildType=preview"
      ;;
  esac
fi

# ───── Final Output ─────
echo "🔧 Resolved build type: ${BUILD_TYPE}"
echo "BUILD_TYPE=${BUILD_TYPE}" >> "$GITHUB_ENV"
echo "buildType=${BUILD_TYPE}" >> "$GITHUB_OUTPUT"