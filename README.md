# ci-action

Reusable CI/CD workflows and scripts for Go projects.

## Reusable Workflows

### ci.yml - Main CI Workflow

Reusable workflow for Go projects that performs validation and testing.

```yaml
name: CI
on: [push, pull_request_target]
jobs:
  build:
    uses: untillpro/ci-action/.github/workflows/ci.yml@main
    with:
      short_test: 'false'      # Optional: run short tests only
      go_race: 'false'         # Optional: enable race detector
      install_tinygo: 'false'  # Optional: install TinyGo (needed for voedger)
      extra_env: ''            # Optional: additional environment variables (multi-line KEY=VALUE)
    secrets:
      reporeading_token: ${{ secrets.REPOREADING_TOKEN }}
```

**What it does:**

**Job 1: `validate-code`**
1. Detects project language (Go or Node.js)
2. Checks out code
3. Checks hidden folders (no `.folder` allowed)
4. Checks bash script headers (`#!/usr/bin/env bash` + `set -Eeuo pipefail`)
5. Checks copyright notices

**Job 2: `run-tests-go`** (runs only if language is Go)
1. Checks out code and sets up Go (auto-detects version from `go.work`/`go.mod`)
2. Optionally installs TinyGo (if `install_tinygo: 'true'`)
3. Applies extra environment variables (if `extra_env` provided)
4. Validates `go.mod` (no local `replace` directives)
5. Runs Go tests with private repo access (`github.com/untillpro/*`, `github.com/heeus/*`)
6. Runs linters (`golangci-lint`)
7. Runs vulnerability check (`govulncheck`) unless `short_test: 'true'`

### ci_pr.yml - Pull Request Workflow

Extends `ci.yml` with pull request-specific checks. Automatically cancels duplicate workflow runs for the same PR using GitHub's native concurrency control.

```yaml
name: CI-PR
on: pull_request_target
jobs:
  build:
    uses: untillpro/ci-action/.github/workflows/ci_pr.yml@main
    with:
      short_test: 'false'        # Optional: same as ci.yml
      go_race: 'false'           # Optional: same as ci.yml
      install_tinygo: 'false'    # Optional: same as ci.yml
      extra_env: ''              # Optional: same as ci.yml
    secrets:
      reporeading_token: ${{ secrets.REPOREADING_TOKEN }}
```

**What it does:**

**Concurrency Control:**
- Automatically cancels previous workflow runs for the same PR when a new commit is pushed

**Job 1: `pull-request-check`**
- Checks PR file size limits

**Job 2: `CI`**
- Calls `ci.yml` with all the same inputs and secrets

### cp.yml - Cherry Pick Workflow

Cherry pick commits to rc/release branches via issue creation.

### rc.yml - Release Candidate Workflow

Re-create release branch from main.

### create_issue.yml - Create Issue Workflow

Create issues programmatically.

## Composite Action

### checkout-and-setup-go

Checkout repository and setup Go with auto-detected version:

```yaml
- uses: untillpro/ci-action/checkout-and-setup-go@main
  with:
    fetch_depth: 0
    # ref: ${{ github.event.pull_request.head.sha }}
```

**Inputs:**
- `fetch_depth` - Fetch depth for checkout (default: 1)
- `ref` - Git ref to checkout
- `token` - Token for checkout
- `submodules` - Submodules option
- `path` - Path to checkout into (default: ".")
- `go-version` - Go version (auto-detected from go.work/go.mod if not specified)

**Outputs:**
- `go-version` - The Go version being used

## Scripts

Located in `scripts/` directory and called directly via `curl` from workflows.

### Core CI Scripts
| Script | Purpose |
|--------|---------|
| `detect_language.sh` | Auto-detect project language (Go or Node.js) |
| `detect-go-version.sh` | Detect Go version from `go.work`/`go.mod` |
| `ci_go.sh` | Run Go tests with private repo access |
| `ci_node_js.sh` | Run Node.js tests |

### Validation Scripts
| Script | Purpose |
|--------|---------|
| `reject_hidden_folders.sh` | Validate repository structure (no hidden folders) |
| `check_sh_header.sh` | Validate bash script headers |
| `check_copyright.sh` | Validate copyright notices |
| `check_gomod.sh` | Validate `go.mod` has no local `replace` directives |

### Go Tooling Scripts
| Script | Purpose |
|--------|---------|
| `run-linters.sh` | Run `golangci-lint` |
| `install-tinygo.sh` | Install TinyGo for a specific Go version |

### PR Scripts
| Script | Purpose |
|--------|---------|
| `checkPR.sh` | Check PR file size limits |

### Release & Issue Management Scripts
| Script | Purpose |
|--------|---------|
| `cp.sh` | Cherry-pick commits to rc/release branches |
| `rc.sh` | Create release candidate branch |
| `git-release.sh` | Git release utilities |
| `createissue.sh` | Create GitHub issues |
| `close-issue.sh` | Close GitHub issues |
| `add-issue-commit.sh` | Add comment to issue |
| `unlinkmilestone.sh` | Unlink milestone from issue |
| `domergepr.sh` | Merge pull request |

### Utility Scripts
| Script | Purpose |
|--------|---------|
| `updateConfig.sh` | Update configuration |
| `deleteDockerImages.sh` | Delete Docker images |

## Setup

### Required Secrets

**`REPOREADING_TOKEN`** (required)
- Create a personal access token: [GitHub Settings > Tokens](https://github.com/settings/tokens)
- Needs `repo` scope to access private repositories
- Add as repository or organization secret
- Used for:
  - Checking out code
  - Accessing private Go modules (`github.com/untillpro/*`, `github.com/heeus/*`)

### Example Workflow Setup

**For regular CI (push and PR):**

```yaml
# .github/workflows/ci.yml
name: CI
on:
  push:
    branches: [main]
  pull_request_target:

jobs:
  build:
    uses: untillpro/ci-action/.github/workflows/ci.yml@main
    secrets:
      reporeading_token: ${{ secrets.REPOREADING_TOKEN }}
```

**For pull requests:**

```yaml
# .github/workflows/ci-pr.yml
name: CI-PR
on:
  pull_request_target:

jobs:
  build:
    uses: untillpro/ci-action/.github/workflows/ci_pr.yml@main
    secrets:
      reporeading_token: ${{ secrets.REPOREADING_TOKEN }}
```

**For voedger (with TinyGo and extra env):**

```yaml
name: CI
on: [push, pull_request_target]

jobs:
  build:
    uses: untillpro/ci-action/.github/workflows/ci.yml@main
    with:
      install_tinygo: 'true'
      extra_env: |
        VOEDGER_SPECIFIC_VAR=value
        ANOTHER_VAR=value2
    secrets:
      reporeading_token: ${{ secrets.REPOREADING_TOKEN }}
```

## License

The scripts and documentation in this project are released under the [MIT License](LICENSE)

