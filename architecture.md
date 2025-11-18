# untillpro/ci-action Architecture

The untillpro/ci-action is a GitHub Action designed to provide continuous integration capabilities for Go and Node.js projects. Its architecture is implemented as a **composite action** using bash scripts, providing a lightweight and transparent CI/CD solution without Node.js dependencies.

---

## Implementation Overview

**Type**: Composite GitHub Action
**Runtime**: Bash shell
**Dependencies**: Standard Unix tools + GitHub CLI (for publishing)
**Configuration**: [action.yml](./action.yml)

---

## Core Components

### Action Configuration

- **[action.yml](./action.yml)**: Defines the composite action with all inputs, outputs, and execution steps
  - Configures the action as `using: 'composite'`
  - Maps all inputs to environment variables (`INPUT_*`)
  - Executes the main bash script: `scripts/ci_main.sh`

### Main CI Scripts

The core CI functionality is implemented in bash scripts located in the `scripts/` directory:

#### Primary CI Scripts

- **[ci_main.sh](./scripts/ci_main.sh)**: Main orchestration script that coordinates the entire CI process
  - Reads inputs from environment variables
  - Calls validation scripts
  - Detects project language
  - Runs language-specific build and test workflows
  - Triggers publishing when appropriate

- **[reject_hidden_folders.sh](./scripts/reject_hidden_folders.sh)**: Validates repository structure
  - Rejects unexpected hidden folders
  - Allows: `.git`, `.github`, `.husky`, `.augment`
  - Supports ignore list

- **[detect_language.sh](./scripts/detect_language.sh)**: Auto-detects project language
  - Returns: `go`, `node_js`, or `unknown`
  - Checks for `go.mod`, `*.go` files, or JavaScript/TypeScript files

- **[check_source_copyright.sh](./scripts/check_source_copyright.sh)**: Validates source file compliance
  - Checks copyright notices in `.go` and `.js` files
  - Validates LICENSE file consistency
  - Skips files marked with "DO NOT EDIT"

- **[check_gomod.sh](./scripts/check_gomod.sh)**: Validates Go module configuration
  - Ensures `go.mod` has no local replace directives
  - Prevents accidental commits with local dependencies

- **[publish_release.sh](./scripts/publish_release.sh)**: Handles release publishing
  - Creates GitHub releases with timestamp-based versioning
  - Uploads assets as zip files
  - Manages release retention (keeps N most recent)
  - Uses GitHub CLI (`gh`) for API interactions

#### Additional Utility Scripts

The scripts directory also contains specialized bash scripts for extended functionality:

- Code linting: [run-linters.sh](./scripts/run-linters.sh) - Runs golangci-lint
- Vulnerability checking: [vulncheck.sh](./scripts/vulncheck.sh), [execgovuln.sh](./scripts/execgovuln.sh)
- Testing: [test_subfolders.sh](./scripts/test_subfolders.sh), [test_subfolders.sh](./scripts/test_subfolders.sh)
- Release management: [git-release.sh](./scripts/git-release.sh)
- Copyright checking: [check_copyright.sh](./scripts/check_copyright.sh)
- Configuration updates: [updateConfig.sh](./scripts/updateConfig.sh)
- PR management: [checkPR.sh](./scripts/checkPR.sh), [domergepr.sh](./scripts/domergepr.sh)
- Issue management: [createissue.sh](./scripts/createissue.sh), [close-issue.sh](./scripts/close-issue.sh)


### Composite Helper Actions

In addition to the main composite action defined in [action.yml](./action.yml), this repository exposes a focused composite action for Go projects:

- **[checkout-and-setup-go/action.yml](./checkout-and-setup-go/action.yml)**
  - Wraps repository checkout (`actions/checkout`) and Go toolchain setup (`actions/setup-go`).
  - Detects the Go version via `scripts/detect-go-version.sh`.
  - Uses `actions/setup-go` built-in module cache (`cache: true`).
  - Inputs:
    - `fetch_depth` — fetch depth passed to `actions/checkout` (default: `1`).
    - `ref` — git ref to checkout; defaults to `github.ref` when omitted.
    - `token`, `submodules`, `path` — forwarded directly to `actions/checkout`.

Typical usage in a workflow:

```yaml
- name: Checkout and setup Go
  id: go-setup
  uses: untillpro/ci-action/checkout-and-setup-go@main
  with:
    fetch_depth: 0
    # ref: ${{ github.event.pull_request.head.sha }}  # optional
```

### Reusable Workflow Templates

The `.github/workflows/` directory contains reusable GitHub workflow templates that use this action:

- **Go workflows**:
  - [ci_reuse_go.yml](.github/workflows/ci_reuse_go.yml) - Standard Go CI with linting
  - [ci_reuse_go_pr.yml](.github/workflows/ci_reuse_go_pr.yml) - Go CI for pull requests
  - [ci_reuse_go_cas.yml](.github/workflows/ci_reuse_go_cas.yml) - Go CI with custom environment
  - [ci_reuse_go_norebuild.yml](.github/workflows/ci_reuse_go_norebuild.yml) - Go CI without rebuild
- **Node.js workflows**:
  - [ci_reuse.yml](.github/workflows/ci_reuse.yml) - Node.js CI
- **Specialized workflows**:
  - [cp.yml](.github/workflows/cp.yml) - Cherry-picking
  - [rc.yml](.github/workflows/rc.yml) - Release candidates
  - [ci-extrachecks.yml](.github/workflows/ci-extrachecks.yml) - Extra security checks (govulncheck)


---

## Execution Flow

The composite action executes the following workflow via `ci_main.sh`:

### 1. Input Processing
- Reads all inputs from environment variables (`INPUT_*`)
- Extracts repository owner and name
- Determines current branch name
- Prints context information (repository, organization, actor, event, branch)

### 2. Repository Validation
- **Hidden Folders Check** (`reject_hidden_folders.sh`)
  - Scans for unexpected hidden folders
  - Allows: `.git`, `.github`, `.husky`, `.augment`
  - Respects ignore list

### 3. Source Code Validation
- **Copyright Check** (`check_source_copyright.sh`)
  - Validates copyright notices in `.go` and `.js` files
  - Checks LICENSE file consistency
  - Skips files with "DO NOT EDIT" marker
  - Respects ignore list and `ignore-copyright` flag

### 4. Language Detection
- **Auto-detection** (`detect_language.sh`)
  - Checks for `go.mod` or `*.go` files → Go project
  - Checks for `*.js`, `*.jsx`, `*.ts`, `*.tsx` files → Node.js project
  - Returns `unknown` if neither detected

### 5. Language-Specific Build & Test

#### For Go Projects:
1. **Go Module Validation** (`check_gomod.sh`)
   - Ensures no local replace directives in `go.mod`

2. **Environment Configuration**
   - Configures `GOPRIVATE` for private repositories
   - Sets up git authentication for private dependencies

3. **Build & Test**
   - Optionally runs `go mod tidy`
   - Runs `go build ./...` (unless `ignore-build` is set)
   - Runs `go test ./...` with optional:
     - Race detection (`-race`)
     - Short mode (`-short`)
     - Custom test folder
     - Codecov integration with coverage reports

4. **Custom Build Command**
   - Executes `build-cmd` if specified

#### For Node.js Projects:
1. **Build & Test**
   - Runs `npm install`
   - Runs `npm run build --if-present`
   - Runs `npm test`

2. **Codecov Integration**
   - Installs codecov globally
   - Runs istanbul coverage
   - Uploads to codecov

### 6. Release Publishing (Optional)
- **Triggered when**:
  - Current branch matches `main-branch` (default: `main`)
  - `publish-asset` is specified

- **Publishing Process** (`publish_release.sh`)
  - Generates timestamp-based version tag (e.g., `20240115.143022.123`)
  - Creates zip archive from asset (file or directory)
  - Creates GitHub release using GitHub CLI
  - Uploads zip asset to release
  - Creates and uploads `deploy.txt` with download URL
  - Manages release retention (deletes old releases, keeps N most recent)
  - Sets GitHub Actions outputs (release_id, release_name, release_html_url, etc.)

---

## Usage in Workflows

The action is designed to be highly configurable through input parameters while providing sensible defaults, making it adaptable to various project requirements within the untillpro ecosystem.

Example usage:

```yaml
- uses: untillpro/ci-action@main
  with:
    organization: 'untillpro,heeus'
    token: ${{ secrets.REPOREADING_TOKEN }}
    codecov-token: ${{ secrets.CODECOV_TOKEN }}
    codecov-go-race: true
    publish-asset: 'my-app'
    publish-keep: 8
```

For additional functionality like linting and vulnerability scanning, use the standalone scripts in separate workflow steps:

```yaml
- name: Linters
  run: curl -s https://raw.githubusercontent.com/untillpro/ci-action/main/scripts/run-linters.sh | bash -s

- name: Vulnerability Check
  run: curl -s https://raw.githubusercontent.com/untillpro/ci-action/main/scripts/vulncheck.sh | bash
```
