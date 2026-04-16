#!/usr/bin/env bash
#
# 02-fork-repo.sh — Fork the lab repository into a target GitHub organization
#
# This script:
#   1. Checks that the GitHub CLI (gh) is installed and authenticated.
#   2. Accepts the target organization name as the first positional argument.
#   3. Forks EmeaAppGbb/AppModLab-ghactions-scale-ghcp-mod into that org.
#   4. Clones the fork locally (if not already cloned).
#   5. Prints next steps.
#
# Usage:
#   ./scripts/02-fork-repo.sh <ORG_NAME>
#
# Example:
#   ./scripts/02-fork-repo.sh my-demo-org
#

set -euo pipefail

# ─── Constants ──────────────────────────────────────────────────────────────
SOURCE_REPO="EmeaAppGbb/AppModLab-ghactions-scale-ghcp-mod"
REPO_NAME="AppModLab-ghactions-scale-ghcp-mod"

# ─── Colour helpers (no-op when stdout is not a terminal) ───────────────────
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  CYAN='\033[0;36m'
  NC='\033[0m' # No Colour
else
  RED='' GREEN='' YELLOW='' CYAN='' NC=''
fi

# ─── Helper functions ───────────────────────────────────────────────────────
info()    { echo -e "${CYAN}ℹ ${NC} $*"; }
success() { echo -e "${GREEN}✔ ${NC} $*"; }
warn()    { echo -e "${YELLOW}⚠ ${NC} $*"; }
error()   { echo -e "${RED}✖ ${NC} $*" >&2; }

# ─── Step 1: Check that gh CLI is installed ─────────────────────────────────
if ! command -v gh &>/dev/null; then
  error "GitHub CLI (gh) is not installed."
  echo ""
  echo "  Install it from: https://cli.github.com/"
  echo ""
  echo "  Quick install options:"
  echo "    macOS   : brew install gh"
  echo "    Windows : winget install --id GitHub.cli"
  echo "    Linux   : https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
  echo ""
  exit 1
fi

success "GitHub CLI (gh) is installed — $(gh --version | head -n1)"

# ─── Step 2: Check that gh is authenticated ─────────────────────────────────
if ! gh auth status &>/dev/null; then
  error "GitHub CLI is not authenticated."
  echo ""
  echo "  Run:  gh auth login"
  echo ""
  exit 1
fi

success "GitHub CLI is authenticated."

# ─── Step 3: Accept ORG_NAME as the first positional argument ───────────────
ORG_NAME="${1:-}"

if [ -z "$ORG_NAME" ]; then
  error "Organization name is required."
  echo ""
  echo "  Usage: $0 <ORG_NAME>"
  echo ""
  exit 1
fi

# ─── Step 4: Verify the organization exists ─────────────────────────────────
info "Verifying organization: ${CYAN}${ORG_NAME}${NC} ..."

HTTP_STATUS=$(gh api "orgs/${ORG_NAME}" --silent -i 2>&1 | head -n1 | awk '{print $2}')

if [ "$HTTP_STATUS" != "200" ]; then
  error "Organization '${ORG_NAME}' was not found (HTTP ${HTTP_STATUS})."
  echo ""
  echo "  • Double-check the spelling."
  echo "  • Make sure the org has been created at:"
  echo "    https://github.com/account/organizations/new?plan=free"
  echo ""
  exit 1
fi

success "Organization '${ORG_NAME}' exists and is accessible."

# ─── Step 5: Fork the repository into the target org ────────────────────────
FORK_FULL_NAME="${ORG_NAME}/${REPO_NAME}"

info "Checking if fork ${CYAN}${FORK_FULL_NAME}${NC} already exists ..."

if gh repo view "$FORK_FULL_NAME" &>/dev/null; then
  warn "Fork '${FORK_FULL_NAME}' already exists — skipping fork creation."
else
  info "Forking ${CYAN}${SOURCE_REPO}${NC} into org ${CYAN}${ORG_NAME}${NC} ..."
  if ! gh repo fork "$SOURCE_REPO" --org "$ORG_NAME" --clone=false; then
    error "Failed to fork '${SOURCE_REPO}' into '${ORG_NAME}'."
    echo ""
    echo "  • Ensure you have permission to create repositories in '${ORG_NAME}'."
    echo "  • Check that the source repo '${SOURCE_REPO}' is accessible."
    echo ""
    exit 1
  fi
  success "Repository forked to ${FORK_FULL_NAME}."
fi

# ─── Step 6: Clone the fork locally (if not already cloned) ────────────────
if [ -d "$REPO_NAME" ]; then
  warn "Directory '${REPO_NAME}' already exists — skipping clone."
  info "To update, run: cd ${REPO_NAME} && git pull"
else
  info "Cloning ${CYAN}${FORK_FULL_NAME}${NC} ..."
  if ! gh repo clone "$FORK_FULL_NAME"; then
    error "Failed to clone '${FORK_FULL_NAME}'."
    exit 1
  fi
  success "Repository cloned to ./${REPO_NAME}"
fi

# ─── Done ───────────────────────────────────────────────────────────────────
echo ""
success "Fork setup complete!"
echo ""
echo "  Next steps:"
echo "    1. cd ${REPO_NAME}"
echo "    2. Review the README.md for lab instructions."
echo "    3. Run the next setup script to configure GitHub Actions."
echo ""
