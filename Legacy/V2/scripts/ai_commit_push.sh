#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "Usage: ./scripts/ai_commit_push.sh \"feat: add home feature scaffold\""
  exit 1
fi

MESSAGE="$*"

git add .

if git diff --cached --quiet; then
  echo "No staged changes to commit."
  exit 1
fi

git commit -m "$MESSAGE"
git push
