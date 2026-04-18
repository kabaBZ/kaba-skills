#!/bin/bash
# Usage: sync-push.sh <skill-name> <commit-message>
# Syncs a local kaba-* skill to the repo and pushes.
# Auto-bumps patch version in marketplace.json and plugin.json.
# copy and reconfigured from https://github.com/lijigang/ljg-skills

set -euo pipefail

SKILL="$1"
MSG="$2"
REPO="$HOME/.claude/kaba-skills-repo"
LOCAL="$HOME/.claude/skills/$SKILL"
TARGET="$REPO/skills/$SKILL"

if [ ! -d "$LOCAL" ]; then
  echo "ERROR: $LOCAL does not exist" >&2
  exit 1
fi

cd "$REPO"
git pull --rebase --quiet
rsync -av --delete --exclude='.git' "$LOCAL/" "$TARGET/"

# Auto-bump patch version in plugin metadata
bump_version() {
  local file="$1"
  local current
  current=$(grep -m1 '"version"' "$file" | sed 's/.*"\([0-9]*\.[0-9]*\.[0-9]*\)".*/\1/')
  local major minor patch
  major=$(echo "$current" | cut -d. -f1)
  minor=$(echo "$current" | cut -d. -f2)
  patch=$(echo "$current" | cut -d. -f3)
  local new_version="$major.$minor.$((patch + 1))"
  sed -i '' "s/\"version\": \"$current\"/\"version\": \"$new_version\"/" "$file"
  echo "$new_version"
}

NEW_VER=$(bump_version ".claude-plugin/plugin.json")
bump_version ".claude-plugin/marketplace.json" > /dev/null

git add "skills/$SKILL" .claude-plugin/
git diff --cached --quiet && { echo "No changes to push."; exit 0; }
git commit -m "$MSG (v$NEW_VER)"
git push
echo "Pushed $SKILL at collection v$NEW_VER"