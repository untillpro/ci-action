# CI-Action Usage Documentation

This directory contains automatically generated documentation showing which repositories use the ci-action.

## Quick Start

To update the usage documentation:

```bash
cd docs
./generate-usage.sh
```

This will:
1. Collect usage data from all untillpro repositories (voedger/voedger instead of untillpro/voedger)
2. Generate a Mermaid visualization
3. Save the output as `ci-action-usages.md` in this directory

## Prerequisites

**GitHub CLI Authentication:**

You must be logged in with `gh` CLI under an account that has read access to `untillpro` repositories:

```bash
# Check if you're logged in
gh auth status

# Login if needed
gh auth login

# Verify you can access untillpro repositories
gh repo list untillpro --limit 5
```

## Output

- **`ci-action-usages.md`** - Mermaid graph showing all ci-action files and which repositories use them

## Manual Process

If you prefer to run the steps manually:

```bash
# From the repository root
cd usage-analyzer

# Step 1: Collect data
./collect.sh

# Step 2: Generate visualization
./visualize.sh mermaid

# Step 3: Move to docs folder
mv ci-action-usages.md ../docs/
```

## See also

- [`scripts/README.md`](scripts/README.md)
