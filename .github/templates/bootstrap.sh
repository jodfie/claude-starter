#!/usr/bin/env bash

set -e

PHASE_HOST="https://secrets.redleif.dev"

cleanup() {
  rm -f "$0"
  git add "$0" CLAUDE.md
  # Include .phase.json if phase init created it
  [ -f .phase.json ] && git add .phase.json
  git commit -m "Initialize claude-code"
}

trap cleanup EXIT

claude -p --permission-mode "acceptEdits" /init

cat <<EOF >>CLAUDE.md

## Task Master AI Instructions

**IMPORTANT!!! Import Task Master's development workflow commands and guidelines, treat as if import is in the main CLAUDE.md file.**

@./.taskmaster/CLAUDE.md
EOF

# Phase initialization
printf "\n"
if command -v phase &>/dev/null; then
  printf "🔐 Setting up Phase secrets manager...\n"
  if phase users whoami --host "$PHASE_HOST" &>/dev/null; then
    printf "   Authenticated with Phase at %s\n" "$PHASE_HOST"
    printf "   Running 'phase init' to link this project to a Phase app...\n"
    phase init --host "$PHASE_HOST" || printf "   ⚠️  phase init skipped (run manually: phase init --host %s)\n" "$PHASE_HOST"
  else
    printf "   ⚠️  Not authenticated with Phase. Run:\n"
    printf "       phase auth --mode token --host %s\n" "$PHASE_HOST"
    printf "       phase init --host %s\n" "$PHASE_HOST"
  fi
else
  printf "⚠️  Phase CLI not found. Install with: pip install phase-cli\n"
  printf "   Then run: phase auth --mode token --host %s\n" "$PHASE_HOST"
  printf "             phase init --host %s\n" "$PHASE_HOST"
fi

printf "\n"
printf "🤖 Done initializing claude-code; committing CLAUDE.md file to git and cleaning up bootstrap script...\n"
printf "🚀 Your repo is now ready for AI-driven development workflows... Have fun!\n"
