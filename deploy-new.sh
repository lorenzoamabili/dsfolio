#!/usr/bin/env bash
# ============================================================
# deploy.sh — Build & publish the Quarto portfolio to GitHub Pages
#
# Usage:
#   ./deploy.sh preview          # local preview only
#   ./deploy.sh build            # build without deploying
#   ./deploy.sh deploy           # build + deploy to GitHub Pages
# ============================================================

# Colours for output
RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${CYAN}▸${NC} $*"; }
ok()    { echo -e "${GREEN}✓${NC} $*"; }
warn()  { echo -e "${YELLOW}⚠${NC} $*"; }
err()   { echo -e "${RED}✗${NC} $*" >&2; exit 1; }

# Change to script directory
cd "$(dirname "$0")" || err "Could not change to script directory"

# ============================================================
# Check dependencies
# ============================================================
check_deps() {
  local missing=()
  
  if ! command -v quarto &>/dev/null; then
    missing+=("Quarto")
    warn "Quarto not found. Install from: https://quarto.org/docs/get-started/"
  fi
  
  if ! command -v git &>/dev/null; then
    missing+=("Git")
    warn "Git not found. Install from: https://git-scm.com/downloads"
  fi
  
  if [ ${#missing[@]} -gt 0 ]; then
    echo ""
    err "Missing dependencies: ${missing[*]}"
  fi
}

# ============================================================
# Commands
# ============================================================

cmd_preview() {
  info "Starting local preview server..."
  echo ""
  echo "  Open your browser to: http://localhost:4200"
  echo "  Press Ctrl+C to stop"
  echo ""
  quarto preview --port 4200 --no-browser
}

cmd_build() {
  info "Building site..."
  quarto render .
  ok "Build complete. Output in _site/"
}

cmd_deploy() {
  # Check if in git repo
  if ! git rev-parse --git-dir &>/dev/null; then
    err "Not a git repository. Run 'git init' first."
  fi
  
  info "Building site..."
  quarto render .
  ok "Build complete"
  
  info "Committing source changes..."
  git add -A
  if git diff --cached --quiet; then
    info "No source changes to commit"
  else
    git commit -m "Update portfolio content"
    git push origin "$(git branch --show-current)"
    ok "Source pushed"
  fi
  
  info "Deploying to gh-pages..."
  git subtree push --prefix _site origin gh-pages
  ok "Deployed!"
  echo ""
  echo "  Your portfolio will be live at:"
  echo "  https://$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1.github.io/')"
  echo ""
  warn "First deploy? Enable GitHub Pages in Settings → Pages → Source: gh-pages"
}

# ============================================================
# Main
# ============================================================

check_deps

case "${1:-}" in
  preview)
    cmd_preview
    ;;
  build)
    cmd_build
    ;;
  deploy)
    cmd_deploy
    ;;
  *)
    echo "Usage: $0 {preview|build|deploy}"
    echo ""
    echo "Commands:"
    echo "  preview  - Start local development server"
    echo "  build    - Build site without deploying"
    echo "  deploy   - Build and deploy to GitHub Pages"
    exit 1
    ;;
esac
