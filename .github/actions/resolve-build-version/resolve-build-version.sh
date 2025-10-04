#!/bin/bash
set -e

# ───── Input Parameters ─────
REF="$1"
EVENT="$2"
INPUT_VERSION="$3"
BUILD_TYPE="$4"

# ───── Determine Version ─────
if [[ "$BUILD_TYPE" == "release" ]]; then
  if [[ "$REF" =~ ^refs/tags/(v?[0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
    VERSION="${BASH_REMATCH[1]}"
  elif [[ -n "$INPUT_VERSION" ]]; then
    # Validate the manual version format
    if [[ "$INPUT_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      VERSION="$INPUT_VERSION"
    else
      echo "❌ Invalid manual release version: '$INPUT_VERSION'"
      echo "Must be in format: vX.Y.Z (no suffixes)"
      exit 1
    fi
  else
    echo "❌ For 'release' builds, either push a Git tag or provide a Semver version input."
    exit 1
  fi

# ───── For release_candidate builds ─────
elif [[ "$BUILD_TYPE" == "release_candidate" ]]; then
  if [[ "$REF" =~ ^refs/tags/(v[0-9]+\.[0-9]+\.[0-9]+-rc\.[0-9]+)$ ]]; then
    VERSION="${BASH_REMATCH[1]}"
    echo "🏷️ Detected RC tag push: $VERSION"
  elif [[ -z "$INPUT_VERSION" ]]; then
    echo "🔍 No version provided — generating next available RC version..."
    BASE_TAG=$(git tag | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+' | sed -E 's/^((v[0-9]+\.[0-9]+\.[0-9]+)).*/\1/' | sort -V | uniq | tail -n 1)
    BASE_TAG=${BASE_TAG:-v0.0.0}
    echo "👀 Using latest base tag: $BASE_TAG"
    VERSION="$($GITHUB_ACTION_PATH/generate-version-for-rc.sh "$BASE_TAG" 2>&1 | tee /dev/stderr | tail -n 1)"
  elif [[ "$INPUT_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+-rc\.[0-9]+$ ]]; then
    echo "🔢 Using provided RC version directly: $INPUT_VERSION"
    VERSION="$INPUT_VERSION"
  else
    echo "🔢 Using provided version as RC base: $INPUT_VERSION"
    VERSION="$($GITHUB_ACTION_PATH/generate-version-for-rc.sh "$INPUT_VERSION" 2>&1 | tee /dev/stderr | tail -n 1)"
  fi

# Manual override for non-RC builds (e.g., preview)
elif [[ "$BUILD_TYPE" != "release" && -n "$INPUT_VERSION" ]]; then
  VERSION="$INPUT_VERSION"

# Pull Request build
elif [[ "$REF" =~ ^refs/pull/([0-9]+)/merge$ ]]; then
  PR_NUMBER=$(printf "%04d" "${BASH_REMATCH[1]}")
  VERSION="PR-${PR_NUMBER}"

# Branch-based manual or CI build
elif [[ "$REF" =~ ^refs/heads/(.+)$ ]]; then
  BRANCH_NAME=$(echo "${BASH_REMATCH[1]}" | tr '/' '-')
  if [[ "$EVENT" == "workflow_dispatch" ]]; then
    VERSION="manual-${BRANCH_NAME}"
  else
    VERSION="${BRANCH_NAME}"
  fi

# Fallback to short commit SHA
else
  SHORT_SHA=$(git rev-parse --short HEAD)
  VERSION="commit-${SHORT_SHA}"
fi

if [[ -z "$VERSION" ]]; then
  VERSION="N/A"
  echo "⚠️ No valid version determined, using fallback: $VERSION"
fi

# Output the result
echo "VERSION=$VERSION" >> $GITHUB_ENV
echo "version=$VERSION" >> $GITHUB_OUTPUT
echo "🏷️ Determined version: $VERSION"