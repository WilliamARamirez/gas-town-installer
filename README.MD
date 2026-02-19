# Gas Town Setup
This script installs all prerequisites for [Gas Town](https://github.com/steveyegge/gastown)
on a fresh Mac Mini. It is safe to run multiple times — already-installed tools will be skipped.
## What Gets Installed
| Tool | Purpose | Min Version |
|------|---------|-------------|
| [Homebrew](https://brew.sh) | macOS package manager | latest |
| [Go](https://go.dev) | Required to build/install Gas Town | 1.24+ |
| [Git](https://git-scm.com) | Version control + worktree support | 2.20+ |
| [Dolt](https://github.com/dolthub/dolt) | Database backend | latest |
| [tmux](https://github.com/tmux/tmux) | Terminal multiplexer for full-stack mode | 3.0+ |
| [Beads (`bd`)](https://github.com/steveyegge/beads) | Git-backed issue tracker | 0.52.0+ |
| [Gas Town (`gt`)](https://github.com/steveyegge/gastown) | Multi-agent workspace manager | latest |
| [Claude Code](https://claude.ai/code) | Default AI agent runtime | latest |
> **Note:** `sqlite3` is pre-installed on macOS and does not need to be installed separately.
## Prerequisites
- A Mac (Intel or Apple Silicon)
- macOS 12 (Monterey) or later
- An internet connection
- Terminal access
No other software needs to be installed before running this script — it handles everything, including Homebrew itself.
## Instructions
### Step 1 — Save the script
Save `gastown-setup.sh` to a convenient location, for example your home directory or a `~/scripts` folder.
### Step 2 — Open Terminal
Open the **Terminal** app (found in `/Applications/Utilities/` or via Spotlight with `⌘ Space` → type `Terminal`).
### Step 3 — Navigate to the script
```bash
cd ~/         # or wherever you saved the file, e.g. cd ~/scripts
```
### Step 4 — Make the script executable
This only needs to be done once:
```bash
chmod +x gastown-setup.sh
```
### Step 5 — Run the script
```bash
./gastown-setup.sh
```
The script will print `[INFO]`, `[SKIP]`, or `[WARN]` messages as it works through each step.
Installation may take a few minutes depending on your internet speed.
### Step 6 — Reload your shell
Once the script completes, reload your shell config so all PATH changes take effect:
```bash
source ~/.zshrc
```
Or simply open a new Terminal window.
### Step 7 — Verify everything installed correctly
```bash
go version       # should sh