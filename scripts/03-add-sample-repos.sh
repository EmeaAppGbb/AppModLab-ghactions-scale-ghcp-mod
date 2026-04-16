#!/usr/bin/env bash
#
# 03-add-sample-repos.sh — Fork sample legacy repositories into a target org
#
# This script:
#   1. Checks that the GitHub CLI (gh) is installed and authenticated.
#   2. Accepts the target organization name as the first positional argument.
#   3. Forks two sample legacy repositories into that org:
#        - EmeaAppGbb/AppModLab-java-8to21-AssetsManager-spec2cloud
#        - EmeaAppGbb/AppModLab-dotnet-4to10-contosouniversity-spec2cloud
#   4. Verifies each fork exists in the target org.
#   5. Prints a summary of all forked repositories.
#
# Usage:
#   ./scripts/03-add-sample-repos.sh <ORG_NAME>
#
# Example:
#   ./scripts/03-add-sample-repos.sh my-demo-org
#

set -euo pipefail

# ─── Constants ──────────────────────────────────────────────────────────────
SOURCE_REPOS=(
  "EmeaAppGbb/AppModLab-java-8to21-AssetsManager-spec2cloud"
  "EmeaAppGbb/AppModLab-dotnet-4to10-contosouniversity-spec2cloud"
)

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

# ─── Step 5: Fork each sample repository into the target org ────────────────
FORKED_REPOS=()
FAILED_REPOS=()

for SOURCE_REPO in "${SOURCE_REPOS[@]}"; do
  REPO_NAME="${SOURCE_REPO##*/}"
  FORK_FULL_NAME="${ORG_NAME}/${REPO_NAME}"

  echo ""
  info "Processing ${CYAN}${SOURCE_REPO}${NC} ..."

  # Check if the fork already exists
  if gh repo view "$FORK_FULL_NAME" &>/dev/null; then
    warn "Fork '${FORK_FULL_NAME}' already exists — skipping fork creation."
    FORKED_REPOS+=("$FORK_FULL_NAME")
    continue
  fi

  # Fork the repository
  info "Forking ${CYAN}${SOURCE_REPO}${NC} into org ${CYAN}${ORG_NAME}${NC} ..."
  if ! gh repo fork "$SOURCE_REPO" --org "$ORG_NAME" --clone=false; then
    error "Failed to fork '${SOURCE_REPO}' into '${ORG_NAME}'."
    echo ""
    echo "  • Ensure you have permission to create repositories in '${ORG_NAME}'."
    echo "  • Check that the source repo '${SOURCE_REPO}' is accessible."
    echo ""
    FAILED_REPOS+=("$SOURCE_REPO")
    continue
  fi

  success "Repository forked to ${FORK_FULL_NAME}."
  FORKED_REPOS+=("$FORK_FULL_NAME")
done

# ─── Step 6: Verify each fork exists in the target org ──────────────────────
echo ""
info "Verifying forked repositories ..."

VERIFIED_COUNT=0
for FORK in "${FORKED_REPOS[@]}"; do
  if gh repo view "$FORK" &>/dev/null; then
    success "Verified: ${FORK}"
    VERIFIED_COUNT=$((VERIFIED_COUNT + 1))
  else
    error "Verification failed: ${FORK} — repository not found."
    FAILED_REPOS+=("$FORK")
  fi
done

# ─── Step 7: Print summary ─────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────────────────────────"
info "Summary"
echo "─────────────────────────────────────────────────────────"
echo ""
echo "  Total sample repos : ${#SOURCE_REPOS[@]}"
echo "  Forked & verified  : ${VERIFIED_COUNT}"
echo "  Failed             : ${#FAILED_REPOS[@]}"
echo ""

if [ ${#FORKED_REPOS[@]} -gt 0 ]; then
  info "Forked repositories:"
  for FORK in "${FORKED_REPOS[@]}"; do
    echo "    • https://github.com/${FORK}"
  done
  echo ""
fi

if [ ${#FAILED_REPOS[@]} -gt 0 ]; then
  error "The following repositories could not be forked or verified:"
  for FAIL in "${FAILED_REPOS[@]}"; do
    echo "    • ${FAIL}"
  done
  echo ""
  exit 1
fi

success "All sample repositories forked successfully!"
echo ""
echo "  Next steps:"
echo "    1. Review each repository in your org at https://github.com/${ORG_NAME}"
echo "    2. Continue with the lab guide to configure GitHub Actions."
echo ""
