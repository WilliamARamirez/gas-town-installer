#!/usr/bin/env bash
# =============================================================================
# gastown-setup.sh
# Fresh Mac Mini setup script for Gas Town multi-agent workspace manager
# Source: https://github.com/steveyegge/gastown
#
# Idempotent: safe to run multiple times. Already-installed tools are skipped.
# =============================================================================
set -euo pipefail
# ── Colors ────────────────────────────────────────────────────────────────────
RED='\\033[0;31m'; GREEN='\\033[0;32m'; YELLOW='\\033[1;33m'; BLUE='\\033[0;34m'; NC='\\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
skip()    { echo -e "${BLUE}[SKIP]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
# ── Helper: install a Homebrew package only if not already installed ──────────
brew_install() {
  local pkg="$1"
  if brew list --formula 2>/dev/null | grep -qx "$pkg"; then
    skip "Homebrew package '$pkg' already installed — skipping."
  else
    info "Installing '$pkg' via Homebrew..."
    brew install "$pkg"
  fi
}
# ── 1. Homebrew ───────────────────────────────────────────────────────────────
install_homebrew() {
  if command -v brew &>/dev/null; then
    skip "Homebrew already installed — skipping."
  else
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # Ensure Homebrew is on PATH for Apple Silicon Macs (safe to re-run)
  if [[ -f /opt/homebrew/bin/brew ]] && ! command -v brew &>/dev/null; then
    info "Adding Homebrew (Apple Silicon) to current PATH..."
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  # Write shell config entry only if not already present
  local brew_init='eval "$(/opt/homebrew/bin/brew shellenv)"'
  local shell_config="$HOME/.zprofile"
  if [[ -f /opt/homebrew/bin/brew ]] && ! grep -qF "$brew_init" "$shell_config" 2>/dev/null; then
    info "Persisting Homebrew PATH in $shell_config..."
    echo "" >> "$shell_config"
    echo "# Homebrew (added by gastown-setup.sh)" >> "$shell_config"
    echo "$brew_init" >> "$shell_config"
  fi
}
# ── 2. Core system tools via Homebrew ────────────────────────────────────────
install_brew_packages() {
  info "Updating Homebrew..."
  brew update --quiet
  brew_install go
  brew_install git
  brew_install tmux
}
# ── 3. Dolt (required database backend) ──────────────────────────────────────
install_dolt() {
  if command -v dolt &>/dev/null; then
    skip "Dolt already installed — skipping."
  else
    info "Installing Dolt via Homebrew..."
    brew_install dolt
  fi
}
# ── 4. Go PATH setup ──────────────────────────────────────────────────────────
configure_go_path() {
  local go_bin="$HOME/go/bin"
  local path_export="export PATH=\\"\\$PATH:$go_bin\\""
  local shell_config
  if [[ "$SHELL" == */zsh ]]; then
    shell_config="$HOME/.zshrc"
  else
    shell_config="$HOME/.bashrc"
  fi
  # Add to PATH for the current session if missing
  if [[ ":$PATH:" != *":$go_bin:"* ]]; then
    info "Adding $go_bin to current session PATH..."
    export PATH="$PATH:$go_bin"
  else
    skip "Go bin already in current PATH — skipping."
  fi
  # Persist to shell config only if not already there
  if grep -qF "$go_bin" "$shell_config" 2>/dev/null; then
    skip "Go bin PATH already in $shell_config — skipping."
  else
    info "Persisting Go bin PATH in $shell_config..."
    echo "" >> "$shell_config"
    echo "# Go binaries (added by gastown-setup.sh)" >> "$shell_config"
    echo "$path_export" >> "$shell_config"
  fi
}
# ── 5. Beads (bd) ─────────────────────────────────────────────────────────────
install_beads() {
  # 'go install' is inherently idempotent — it overwrites with the latest version.
  # We still check first so the user gets a clear [SKIP] vs [INFO] signal.
  if command -v bd &>/dev/null; then
    skip "Beads (bd) already installed — re-installing to ensure latest version..."
  else
    info "Installing Beads CLI (bd >= 0.52.0)..."
  fi
  go install github.com/steveyegge/beads/cmd/bd@latest
}
# ── 6. Gas Town (gt) ──────────────────────────────────────────────────────────
install_gastown() {
  if command -v gt &>/dev/null; then
    skip "Gas Town (gt) already installed — re-installing to ensure latest version..."
  else
    info "Installing Gas Town CLI (gt)..."
  fi
  go install github.com/steveyegge/gastown/cmd/gt@latest
}
# ── 7. Node.js (required for Claude Code) ────────────────────────────────────
install_node() {
  if command -v npm &>/dev/null; then
    skip "Node.js/npm already installed — skipping."
  else
    info "npm not found — installing Node.js via Homebrew..."
    brew_install node
  fi
}
# ── 8. Claude Code CLI ────────────────────────────────────────────────────────
install_claude_code() {
  install_node
  if command -v claude &>/dev/null; then
    skip "Claude Code CLI already installed — skipping."
    # Uncomment the line below if you want to auto-upgrade on re-runs:
    # npm update -g @anthropic-ai/claude-code
  else
    info "Installing Claude Code CLI via npm..."
    npm install -g @anthropic-ai/claude-code
  fi
}
# ── 9. Verify installations ───────────────────────────────────────────────────
verify() {
  echo ""
  info "─── Verifying installations ───"
  local all_ok=true
  check() {
    local label="$1"; shift
    local version_output
    if version_output=$("$@" 2>/dev/null | head -1); then
      echo -e "  ${GREEN}✓${NC} $label: $version_output"
    else
      echo -e "  ${RED}✗${NC} $label: NOT FOUND or failed"
      all_ok=false
    fi
  }
  check "Go"            go version
  check "Git"           git --version
  check "Dolt"          dolt version
  check "tmux"          tmux -V
  check "Beads (bd)"    bd version
  check "Gas Town (gt)" gt version
  check "Claude Code"   claude --version
  echo ""
  if $all_ok; then
    info "All prerequisites verified successfully!"
  else
    warn "Some tools may not be in PATH yet."
    warn "Try opening a new terminal or running: source ~/.zshrc"
  fi
}
# ── Optional: initialize a Gas Town workspace ─────────────────────────────────
# Uncomment the block below if you want to auto-initialize ~/gt after install.
# This is also idempotent — 'gt install' and 'gt enable' are safe to re-run.
#
# setup_workspace() {
#   info "Initializing Gas Town workspace at ~/gt ..."
#   gt install ~/gt --shell
#   cd ~/gt
#   gt enable
#   gt git-init
#   gt doctor
# }
# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  info "Starting Gas Town setup for macOS..."
  echo ""
  install_homebrew
  install_brew_packages
  install_dolt
  configure_go_path
  install_beads
  install_gastown
  install_claude_code
  verify
  echo ""
  info "Setup complete!"
  info "To initialize your workspace, run:"
  echo "    gt install ~/gt --shell"
  echo "    cd ~/gt && gt enable && gt git-init && gt up && gt doctor"
  echo ""
  warn "If any tools show as missing, open a new terminal (or run 'source ~/.zshrc') and re-run this script."
}
main "$@"