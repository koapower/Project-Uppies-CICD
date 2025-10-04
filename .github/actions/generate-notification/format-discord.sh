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
  SUMMARY+="\n\`\`\`"
fi

# --- 🔗 Shorten URLs to suppress Discord embeds ---
shorten_url() {
  curl -s "https://tinyurl.com/api-create.php?url=$1"
}

SHORT_RELEASE_URL=$(shorten_url "$RELEASE_URL")
SHORT_RUN_URL=$(shorten_url "$RUN_URL")

# --- 💬 Combine message and summary first ---
FINAL="$MESSAGE$SUMMARY"

# --- 🪄 Replace long GitHub links with shortened + wrapped ones ---
FINAL=$(echo "$FINAL" | \
  sed -E "s#\[View Release\]\([^)]+\)#[View Release](<${SHORT_RELEASE_URL})#g" | \
  sed -E "s#\[View Pipeline\]\([^)]+\)#[View Pipeline](<${SHORT_RUN_URL})#g")

echo "$FINAL"
