# CI-Action Usage Analyzer

This project analyzes which repositories are using the `https://github.com/untillpro/ci-action` repository in their GitHub Actions workflows.

## Project Structure

```
ci-action-usages/
├── collector/              # Data collection tool
│   └── collector.go
├── visualizer/             # Visualization tools
│   ├── mermaid_view.go
│   └── graphviz_view.go
├── collect.sh              # Script to run collector
├── visualize.sh            # Script to run visualizers
├── outdated-repos.txt      # List of repositories to skip
├── ci-action-data.json     # Generated data (output)
├── ci-action-usages.md     # Generated Mermaid graph (output)
└── ci-action-usages.dot    # Generated Graphviz graph (output)
```

## Architecture

The project is divided into separate programs:

### 1. Data Collector (`collector/collector.go`)

Scans all non-archived repositories from GitHub and collects raw usage data

**What it does:**
- Fetches all non-archived repositories from the `untillpro` GitHub organization
- Identifies all ci-action files (workflows, scripts, action.yml)
- Detects three types of ci-action references:
  - GitHub Action workflow calls: `uses: untillpro/ci-action/.github/workflows/...@branch`
  - Direct action usage: `uses: untillpro/ci-action@branch`
  - Script execution via curl: `curl ... https://raw.githubusercontent.com/untillpro/ci-action/branch/scripts/...`
- Skips repositories listed in `outdated-repos.txt`
- Outputs raw data in JSON format to the root directory

**Configuration:**
- must be logged in in `gh` under account that is able to read `github.com/untillpro/*`

**Usage:**
```bash
cd collector
export GITHUB_TOKEN=$(gh auth token)
go run collector.go
```

**Output:** `ci-action-data.json` - Contains all ci-action files and their usages

### 2. Mermaid Visualizer (`visualizer/mermaid_view.go`)

Reads the JSON data and generates a Mermaid graph visualization

**What it does:**
- Reads the collected JSON data
- Generates a Mermaid graph showing:
  - All ci-action files (left side)
  - Repositories and files that use them (right side)
  - Files marked as "NOT_USED" if they have no references

**Usage:**
```bash
cd visualizer
go run mermaid_view.go <input-json-file> [output-md-file]
```

**Example:**
```bash
cd visualizer
go run mermaid_view.go ../ci-action-data.json ../ci-action-usages.md
```

**Output:** Markdown file with Mermaid graph (default: `ci-action-usages.md`)

### 3. Graphviz Visualizer (`visualizer/graphviz_view.go`)

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
cd visualizer
go run graphviz_view.go <input-json-file> [output-dot-file]
```

**Example:**
```bash
cd visualizer
go run graphviz_view.go ../ci-action-data.json ../ci-action-usages.dot

# Render to SVG (requires Graphviz installed)
dot -Tsvg ../ci-action-usages.dot -o ../ci-action-usages.svg

# Render to PNG
dot -Tpng ../ci-action-usages.dot -o ../ci-action-usages.png
```

**Output:** Graphviz DOT file (default: `ci-action-usages.dot`)

## Complete Workflow

### Using bash scripts (recommended):

```bash
# Step 1: Collect raw data
./collect.sh

# Step 2: Generate visualization
./visualize.sh mermaid    # For Mermaid graph
./visualize.sh graphviz   # For Graphviz DOT/SVG
```

### Using Go directly:

```bash
# Step 1: Collect raw data
cd collector
export GITHUB_TOKEN=$(gh auth token)
go run collector.go
cd ..

# Step 2: Generate mermaid visualization
cd visualizer
go run mermaid_view.go ../ci-action-data.json ../ci-action-usages.md
cd ..

# Or generate graphviz visualization
cd visualizer
go run graphviz_view.go ../ci-action-data.json ../ci-action-usages.dot
cd ..
```
