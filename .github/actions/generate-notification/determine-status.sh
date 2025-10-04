#!/bin/bash
set -euo pipefail

TRACE=""
[[ -n "$PR_NUMBER" ]] && TRACE+="PR #$(printf '%04d' "$PR_NUMBER")"
[[ -n "$BRANCH" ]] && TRACE+="${TRACE:+ | }Branch: \`$BRANCH\`"
[[ -n "$COMMIT" ]] && TRACE+="${TRACE:+ | }Commit: \`$(echo "$COMMIT" | cut -c1-7)\`"

if [[ "$TESTS_HAS_FAILS" == "true" && "$TESTS_TOTAL" != "0" ]]; then
  TITLE="Tests Failed - $VERSION"
  MESSAGE="❌ Some tests failed on version \`$VERSION\`.\n"
  MESSAGE+="✅ Passed: $TESTS_PASSED / $TESTS_TOTAL\n"

  MAX_FAILED_TESTS=5
  FAILED_LIST=$(echo "$TESTS_FAILED_NAMES" | head -n $MAX_FAILED_TESTS)
  TOTAL_FAILED_LINES=$(echo "$TESTS_FAILED_NAMES" | wc -l)

  if [[ "$TOTAL_FAILED_LINES" -gt $MAX_FAILED_TESTS ]]; then
    FAILED_LIST+="\n...and $((TOTAL_FAILED_LINES - MAX_FAILED_TESTS)) more"
  fi

  MESSAGE+="❌ Failed Tests:\n$FAILED_LIST"

  STATUS="failure"
  [[ -n "$TRACE" ]] && MESSAGE="$MESSAGE\n\n$TRACE"
  MESSAGE="$MESSAGE\n\n🔗 [View Pipeline]($RUN_URL)"

elif [[ "$RELEASE" == "success" ]]; then
  if [[ "$DEPLOY" == "success" ]]; then
    TITLE="Release & Deploy Succeeded - $VERSION"
    MESSAGE="✅ Release \`$VERSION\` completed successfully."
    STATUS="success"
  elif [[ "$DEPLOY" == "skipped" ]]; then
    TITLE="Release Succeeded (No Deploy) - $VERSION"
    MESSAGE="✅ Release \`$VERSION\` completed successfully. No deployment targets set."
    STATUS="neutral"
  else
    TITLE="Release Succeeded, Deploy Failed - $VERSION"
    MESSAGE="⚠️ Release \`$VERSION\` succeeded, but deployment failed."
    STATUS="failure"
  fi
  [[ -n "$TRACE" ]] && MESSAGE="$MESSAGE\n$TRACE"
  MESSAGE="$MESSAGE\n📦 [View Release]($RELEASE_URL)   ·   🔗 [View Pipeline]($RUN_URL)"

else
  TITLE="Release Failed - $VERSION"
  if [[ -n "$ERROR" ]]; then
    MESSAGE="❌ Release \`$VERSION\` failed: \`$ERROR\`."
  else
    MESSAGE="❌ Release \`$VERSION\` failed."
  fi
  STATUS="failure"
  [[ -n "$TRACE" ]] && MESSAGE="$MESSAGE\n$TRACE"
  MESSAGE="$MESSAGE\n🔗 [View Pipeline]($RUN_URL)"
fi

echo "TITLE=$TITLE" >> "$GITHUB_ENV"
echo "STATUS=$STATUS" >> "$GITHUB_ENV"
echo "MESSAGE<<EOF" >> "$GITHUB_ENV"
echo "$MESSAGE" >> "$GITHUB_ENV"
echo "EOF" >> "$GITHUB_ENV"