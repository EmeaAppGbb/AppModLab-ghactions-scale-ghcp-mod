#!/usr/bin/env bash
#
# 04-configure-variables.sh — Configure GitHub Actions variables and secrets
#
# This script:
#   1. Checks that the GitHub CLI (gh) is installed and authenticated.
#   2. Accepts the target organization name as the first positional argument.
#   3. Verifies the organization exists via the GitHub API.
#   4. Verifies the forked lab repository exists in the target org.
#   5. Sets repository variables: TARGET_ORG, BLACKLIST_REPOS, TARGET_LANGUAGES.
#   6. Prompts for and sets the GH_PAT repository secret.
#   7. Prints a summary of configured settings.
#
# Usage:
#   ./scripts/04-configure-variables.sh <ORG_NAME>
#
# Example:
#   ./scripts/04-configure-variables.sh my-demo-org
#

set -euo pipefail

# ─── Constants ──────────────────────────────────────────────────────────────
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

# ─── Step 5: Verify the lab repo fork exists in the org ─────────────────────
FULL_REPO="${ORG_NAME}/${REPO_NAME}"

info "Verifying repository: ${CYAN}${FULL_REPO}${NC} ..."

if ! gh repo view "$FULL_REPO" &>/dev/null; then
  error "Repository '${FULL_REPO}' was not found."
  echo ""
  echo "  • Make sure you have forked the lab repo into '${ORG_NAME}'."
  echo "  • Run:  ./scripts/02-fork-repo.sh ${ORG_NAME}"
  echo ""
  exit 1
fi

success "Repository '${FULL_REPO}' exists."

# ─── Step 6: Set repository variables ───────────────────────────────────────
echo ""
info "Configuring repository variables for ${CYAN}${FULL_REPO}${NC} ..."
echo ""

# TARGET_ORG (required)
info "Setting TARGET_ORG = ${CYAN}${ORG_NAME}${NC}"
gh variable set TARGET_ORG --body "$ORG_NAME" --repo "$FULL_REPO"
success "TARGET_ORG set."

# BLACKLIST_REPOS (optional — default: exclude the lab repo itself)
BLACKLIST_DEFAULT="${REPO_NAME},.github"
info "Setting BLACKLIST_REPOS = ${CYAN}${BLACKLIST_DEFAULT}${NC}"
gh variable set BLACKLIST_REPOS --body "$BLACKLIST_DEFAULT" --repo "$FULL_REPO"
success "BLACKLIST_REPOS set."

# TARGET_LANGUAGES (optional — default: both)
info "Setting TARGET_LANGUAGES = ${CYAN}both${NC}"
gh variable set TARGET_LANGUAGES --body "both" --repo "$FULL_REPO"
success "TARGET_LANGUAGES set."

# ─── Step 7: Set the GH_PAT secret ─────────────────────────────────────────
echo ""
info "Setting the GH_PAT repository secret ..."
echo ""
echo "  You will be prompted to paste your Personal Access Token."
echo "  The token needs the following scopes: ${CYAN}repo${NC}, ${CYAN}read:org${NC}"
echo ""
echo "  Create one at: https://github.com/settings/tokens/new?scopes=repo,read:org"
echo ""
gh secret set GH_PAT --repo "$FULL_REPO"
success "GH_PAT secret set."

# ─── Step 8: Print summary ─────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────────────────────────"
info "Summary"
echo "─────────────────────────────────────────────────────────"
echo ""
echo "  Repository : ${FULL_REPO}"
echo ""
echo "  Variables:"
echo "    TARGET_ORG       = ${ORG_NAME}"
echo "    BLACKLIST_REPOS  = ${BLACKLIST_DEFAULT}"
echo "    TARGET_LANGUAGES = both"
echo ""
echo "  Secrets:"
echo "    GH_PAT           = ********"
echo ""

success "Configuration complete! You're ready to run the workflows."
echo ""
echo "  Next steps:"
echo "    1. Go to https://github.com/${FULL_REPO}/actions"
echo "    2. Run the '01 — Discover Repos' workflow to verify everything works."
echo ""
