#!/usr/bin/env bash
# ============================================================
# deploy.sh — Build & publish the Quarto portfolio to GitHub Pages
#
# Usage:
#   chmod +x deploy.sh
#   ./deploy.sh                  # build + push
#   ./deploy.sh --preview        # local preview only (no push)
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

#  colours for output 
RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${CYAN}[info]${NC}  $*"; }
ok()    { echo -e "${GREEN}[ok]${NC}    $*"; }
err()   { echo -e "${RED}[err]${NC}   $*"; exit 1; }

#  check dependencies 
command -v quarto &>/dev/null || err "Quarto is not installed. Visit https://quarto.org/download/"
command -v git    &>/dev/null || err "Git is not installed."

#  parse flags 
PREVIEW=false
for arg in "$@"; do
  [[ "$arg" == "--preview" ]] && PREVIEW=true
done

# ============================================================
# 1. PREVIEW MODE — just render locally and open in browser
# ============================================================
if [[ "$PREVIEW" == true ]]; then
  info "Running local preview (no deployment)…"
  quarto preview
  exit 0
fi

# ============================================================
# 2. FULL BUILD + DEPLOY
# ============================================================

#  make sure we are inside a git repo 
git rev-parse --git-dir &>/dev/null || err "Not inside a git repo. Run 'git init' first."

info "Building site with Quarto…"
quarto render .
ok  "Build finished. Output in ./_site/"

#  push to origin (main/master) first so notebooks are tracked 
info "Committing & pushing source…"
git add -A
if git diff --cached --quiet; then
  info "Nothing to commit on source branch."
else
  git commit -m "chore: update portfolio notebooks and content"
  git push origin HEAD
  ok "Source pushed."
fi

#  deploy _site/ to gh-pages branch 
info "Deploying to GitHub Pages (gh-pages branch)…"
# This creates an orphan gh-pages branch containing only _site contents.
# It is safe to run repeatedly — it force-pushes every time.
git subtree push --prefix _site origin gh-pages -f
ok  "Deployed! Your site will be live shortly at:"
echo ""
echo "    https://yourusername.github.io/portfolio/"
echo ""
info "If this is your first deploy, enable GitHub Pages in:"
echo "    Repository Settings → Pages → Source: gh-pages branch"
