#!/bin/bash
MESSAGE="$1"
RUN_URL="$2"
RELEASE_URL="$3"

SUMMARY=""
if ls deploy-results/*.json 1> /dev/null 2>&1; then
  SUMMARY+="\n\`\`\`\n"
  SUMMARY+="Target      | Status | Details\n"
  SUMMARY+="------------|--------|----------------------\n"
  while IFS= read -r file; do
    TARGET=$(basename "$file" .json)
    STATUS=$(jq -r '.status' "$file")
    NOTE=$(jq -r '.note' "$file")
    printf -v ROW "%-11s | %-6s | %s\n" "$TARGET" "$STATUS" "$NOTE"
    SUMMARY+="$ROW"
  done < <(find deploy-results -type f -name "*.json" | sort)
  SUMMARY+="\`\`\`"
fi

FINAL="$MESSAGE$SUMMARY"
FINAL=$(echo "$FINAL" | sed "s#\\[View Pipeline\\]($RUN_URL)#<${RUN_URL}|View Pipeline>#g")
FINAL=$(echo "$FINAL" | sed "s#\\[View Release\\]($RELEASE_URL)#<${RELEASE_URL}|View Release>#g")
echo "$FINAL"
