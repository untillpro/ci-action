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
      short_test: 'false'      # Run short tests only
      go_race: 'false'         # Enable race detector
      install_tinygo: 'false'  # Install TinyGo
      extra_env: ''            # Additional environment variables
    secrets:
      reporeading_token: ${{ secrets.REPOREADING_TOKEN }}
```

**What it does:**
1. Detects Go language
2. Checks hidden folders
3. Checks bash script headers
4. Checks copyright notices
5. Validates go.mod (no local replaces)
6. Runs tests
7. Runs linters (golangci-lint)
8. Runs vulnerability check (govulncheck)

### ci_pr.yml - PR Workflow

Extends ci.yml with pull request-specific checks:

```yaml
name: CI-PR
on: pull_request_target
jobs:
  build:
    uses: untillpro/ci-action/.github/workflows/ci_pr.yml@main
    with:
      running_workflow: 'CI-PR'  # Cancel duplicate workflows
    secrets:
      reporeading_token: ${{ secrets.REPOREADING_TOKEN }}
      personal_token: ${{ secrets.PERSONAL_TOKEN }}
```

**Additional checks:**
- Cancel duplicate running workflows
- Check PR file size limits

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

Located in `scripts/` directory:

| Script | Purpose |
|--------|---------|
| `detect_language.sh` | Auto-detect Go projects |
| `detect-go-version.sh` | Detect Go version from go.work/go.mod |
| `reject_hidden_folders.sh` | Validate repository structure |
| `check_copyright.sh` | Validate copyright notices |
| `check_gomod.sh` | Validate go.mod has no local replaces |
| `check_sh_header.sh` | Validate bash script headers |
| `ci_go.sh` | Run Go tests |
| `run-linters.sh` | Run golangci-lint |
| `install-tinygo.sh` | Install TinyGo |
| `checkPR.sh` | Check PR file size |
| `cancelworkflow.sh` | Cancel duplicate workflows |
| `cp.sh` | Cherry pick commits |
| `rc.sh` | Create release candidate |
| `git-release.sh` | Git release utilities |
| `createissue.sh` | Create GitHub issues |
| `close-issue.sh` | Close GitHub issues |
| `add-issue-commit.sh` | Add comment to issue |
| `unlinkmilestone.sh` | Unlink milestone from issue |
| `domergepr.sh` | Merge pull request |
| `updateConfig.sh` | Update configuration |
| `deleteDockerImages.sh` | Delete Docker images |

## Setup

1. Create a personal access token: [GitHub Settings > Tokens](https://github.com/settings/tokens)
2. Add secret `REPOREADING_TOKEN` to your repository
3. Create workflow file calling the reusable workflows

## License

The scripts and documentation in this project are released under the [MIT License](LICENSE)

