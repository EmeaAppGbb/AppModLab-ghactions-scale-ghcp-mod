#!/usr/bin/env bash
#
# 01-setup-org.sh — Verify prerequisites and validate a GitHub organization
#
# This script:
#   1. Checks that the GitHub CLI (gh) is installed and authenticated.
#   2. Prints guidance on creating a GitHub organization (if needed).
#   3. Accepts the organization name as the first positional argument.
#   4. Verifies the organization exists via the GitHub API.
#
# Usage:
#   ./scripts/01-setup-org.sh <ORG_NAME>
#
# Example:
#   ./scripts/01-setup-org.sh my-demo-org
#

set -euo pipefail

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

# ─── Step 3: Print guidance on creating a GitHub organization ───────────────
echo ""
info "If you haven't created a GitHub organization yet, follow these steps:"
echo ""
echo "  1. Go to https://github.com/account/organizations/new?plan=free"
echo "  2. Choose a unique organization name (e.g. 'my-demo-org')."
echo "  3. Set the contact email and choose 'My personal account' as owner."
echo "  4. Skip the 'Add members' step (you can add them later)."
echo "  5. Once created, pass the org name to this script."
echo ""

# ─── Step 4: Accept ORG_NAME as the first positional argument ───────────────
ORG_NAME="${1:-}"

if [ -z "$ORG_NAME" ]; then
  error "Organization name is required."
  echo ""
  echo "  Usage: $0 <ORG_NAME>"
  echo ""
  exit 1
fi

info "Verifying organization: ${CYAN}${ORG_NAME}${NC} ..."

# ─── Step 5: Verify the organization exists via the GitHub API ──────────────
# The /orgs/:org endpoint returns 200 for valid orgs, 404 otherwise.
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

# ─── Done ───────────────────────────────────────────────────────────────────
echo ""
success "Setup check complete. You're ready to proceed!"
echo ""
echo "  Next step → run the discovery workflow or continue with the lab guide."
echo ""
