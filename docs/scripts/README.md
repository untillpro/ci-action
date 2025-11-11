# CI-Action Usage Analyzer

This project analyzes which repositories are using the `https://github.com/untillpro/ci-action` repository in their GitHub Actions workflows.

## Architecture

The project is divided into separate programs, implemented in **Python**:

### 1. Data Collector (`collector.py`)

Scans all non-archived repositories from GitHub and collects raw usage data

**What it does:**

- **Authentication:** Uses `gh auth token` (via `collect.sh`) to get GitHub token from `GITHUB_TOKEN` env variable
- **Fetches repositories:** Queries GitHub API (`GET /orgs/untillpro/repos`) for all non-archived repos, skips those in `outdated-repos.txt`
- **Discovers ci-action files:** Lists `action.yml`, `.github/workflows/*.yml`, and `scripts/*.sh` via GitHub API (no git clone)
- **Scans for usage:** Downloads `.github` directory files directly from GitHub, scans content in-memory for:
  - Workflow calls: `uses: untillpro/ci-action/.github/workflows/...@branch`
  - Action usage: `uses: untillpro/ci-action@branch`
  - Curl scripts: `curl ... https://raw.githubusercontent.com/untillpro/ci-action/.../scripts/...`
- **Outputs:** `ci-action-data.json` with all ci-action files and their usages (no local clones created)

**Requirements:**

- Python 3.6+ (no external dependencies - uses only standard library)
- Must be logged in with `gh` CLI under an account that can read `github.com/untillpro/*`
- Graphviz (optional, only needed to render DOT files to SVG/PNG)

**Usage:**

```bash
./collect.sh
```

**Output:** `ci-action-data.json` - Contains all ci-action files and their usages

### 2. Mermaid Visualizer (`visualizer_mermaid.py`)

Reads the JSON data and generates a Mermaid graph visualization

**What it does:**

- Reads the collected JSON data
- Generates a Mermaid graph showing:
  - Incoming calls section (which repos call each ci-action file)
  - Outgoing calls section (which ci-action files each repo calls)
  - Visual graph with all relationships

**Usage:**

```bash
./visualize.sh mermaid
```

**Output:** Markdown file with Mermaid graph (default: `ci-action-usages.md`)

### 3. Graphviz Visualizer (`visualizer_graphviz.py`)

Reads the JSON data and generates a Graphviz DOT format visualization

**What it does:**

- Reads the collected JSON data
- Generates a Graphviz DOT graph with:
  - CI-action files grouped in a blue cluster
  - Repository files grouped by repository in green clusters
  - Unused files highlighted in red
  - Used files highlighted in yellow
  - Directed edges showing usage relationships

**Usage:**

```bash
./visualize.sh graphviz
```

**Output:** Graphviz DOT file (default: `ci-action-usages.dot`)

## Complete Workflow

```bash
# Step 1: Collect raw data
./collect.sh

# Step 2: Generate visualization
./visualize.sh mermaid    # For Mermaid graph
./visualize.sh graphviz   # For Graphviz DOT/SVG
```
