# ci-action

Continuous Integration action for go- and node- projects

**Implementation**: This action is implemented as a **composite action** using bash scripts, providing a lightweight and transparent CI/CD solution without Node.js dependencies.

## Features

* **Repository Validation**
  * Reject ".*" folders (except `ignore` folders and `.git`, `.github`, `.husky`, `.augment`)
* **Source Code Validation** (except `ignore` and first comments which include `DO NOT EDIT`)
  * Reject sources which do not have "Copyright" word in first comment
  * Reject sources which have LICENSE word in first comment but LICENSE file does not exist
* **Go Project Validation**
  * Reject go.mod with local replaces
* **Go Projects**
  * Auto-detect Go projects (via `go.mod` or `*.go` files)
  * Configure GOPRIVATE for private repositories
  * Run `go mod tidy` (optional)
  * Run `go test ./...` with optional race detection and short mode
  * Support for custom test folders
  * Codecov integration with coverage reports
* **Node.js Projects**
  * Auto-detect Node.js projects (via `*.js`, `*.jsx`, `*.ts`, `*.tsx` files)
  * Run `npm install`, `npm run build --if-present` and `npm test`
  * Codecov integration

**Note**: Linting (golangci-lint) and vulnerability checks (govulncheck) are available as separate scripts in the `scripts/` directory and are typically run as separate workflow steps. See the reusable workflows in `.github/workflows/` for examples.

## Usage

```yaml
- uses: untillpro/ci-action@main
  with:

    # The name of the organization(s) on GitHub containing private repositories (comma separated)
    organization: 'untillpro'

    # Auth token used to fetch dependencies from private repositories
    token: ''

    # Codecov token
    codecov-token: ''

    # Codecov: use Go Race Detector
    codecov-go-race: true

    # File / dir name to publish
    publish-asset: ''

    # Auth token used to publish
    publish-token: ${{ github.token }}

    # Number of kept releases (0 - all)
    publish-keep: 8

    # Repository name with owner. For example, untillpro/ci-action
    repository: ${{ github.repository }}

    # Only for go-projects: execute `go mod tidy`
    run-mod-tidy: true

    # Main branch name
    main-branch: 'main'

    # Do not check the copyright in first comments of source code
    ignore-copyright: false

    # Test only in folder
    test-folder: ''

    # Short tests
    short-test: false

    # Stop tests
    stop-test: false

    # Command to build project
    build-cmd: ''
```

## Outputs

In case of publish release:

* `release_id`: The ID of the created Release
* `release_name`: The name (version) of the created Release
* `release_html_url`: The URL users can navigate to in order to view the release
* `release_upload_url`: The URL for uploading assets to the release
* `asset_browser_download_url`: The URL users can navigate to in order to download the uploaded asset

## Scenarios

### Creating CODECOV_TOKEN

* Go to appropriate codecov resource, e.g. <https://codecov.io/gh/untillpro/ci-action>
* Copy token from there
* Use it for CODECOV_TOKEN secret, say <https://github.com/untillpro/ci-action/settings/secrets>

### Go project

* If private modules are used:
  * [Create personal access token](https://github.com/settings/tokens)
    * [See also](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line#creating-a-token)
  * Create secret with the received token named "REPOREADING_TOKEN"
* For automatic uploading reports to [Codecov](https://codecov.io/)
  * Create secret with Codecov token named "CODECOV_TOKEN"
* Create action workflow "ci.yml" with the following contents:

```yaml
name: CI-Go
on: [push, pull_request_target]
jobs:
  build:
    runs-on: ubuntu-22.04
    steps:
      - name: Checkout and setup Go
        id: go-setup
        uses: untillpro/ci-action/checkout-and-setup-go@main
        with:
          fetch_depth: 0
          # ref: ${{ github.event.pull_request.head.sha }}  # optional for PRs

      - name: CI
        uses: untillpro/ci-action@main
        with:
          token: ${{ secrets.REPOREADING_TOKEN }}
          codecov-token: ${{ secrets.CODECOV_TOKEN }}
```

### Go project with TinyGo

For projects requiring TinyGo:

```yaml
name: CI-Go-TinyGo
on: [push, pull_request_target]
jobs:
  build:
    runs-on: ubuntu-22.04
    steps:
      - name: Checkout and setup Go
        id: go-setup
        uses: untillpro/ci-action/checkout-and-setup-go@main
        with:
          fetch_depth: 0
          # ref: ${{ github.event.pull_request.head.sha }}  # optional for PRs

      - name: Install TinyGo
        run: |
          curl -s https://raw.githubusercontent.com/untillpro/ci-action/main/scripts/install-tinygo.sh | bash -s "${{ steps.go-setup.outputs.go-version }}"

      - name: CI
        uses: untillpro/ci-action@main
        with:
          token: ${{ secrets.REPOREADING_TOKEN }}
          codecov-token: ${{ secrets.CODECOV_TOKEN }}
```

### Node.js project

* For automatic uploading reports to [Codecov](https://codecov.io/)
  * Create secret with Codecov token named "CODECOV_TOKEN"
* Create action workflow "ci.yml" with the following contents:

```yaml
name: CI-Node.js
on: [push, pull_request_target]
jobs:
  build:
    runs-on: ubuntu-22.04
    steps:
    - name: Set up Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20.x'
    - name: Checkout
      uses: actions/checkout@v4
    - name: Cache Node - npm
      uses: actions/cache@v4
      with:
        path: ~/.npm
        key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
        restore-keys: |
          ${{ runner.os }}-node-
    - name: CI
      uses: untillpro/ci-action@main
      with:
        codecov-token: ${{ secrets.CODECOV_TOKEN }}
```
### Reusable workflows

For repositories that want to reuse the CI logic from this repository, you can call the reusable workflows via `workflow_call`.

**Go reusable workflow**

```yaml
name: CI-Go
on: [push, pull_request_target]
jobs:
  build:
    uses: untillpro/ci-action/.github/workflows/ci_reuse_go.yml@main
    secrets:
      reporeading_token: ${{ secrets.REPOREADING_TOKEN }}
      codecov_token: ${{ secrets.CODECOV_TOKEN }}
```

**Go PR reusable workflow**

```yaml
name: CI-Go-PR
on: pull_request_target
jobs:
  build:
    uses: untillpro/ci-action/.github/workflows/ci_reuse_go_pr.yml@main
    secrets:
      reporeading_token: ${{ secrets.REPOREADING_TOKEN }}
      codecov_token: ${{ secrets.CODECOV_TOKEN }}
      personal_token: ${{ secrets.PERSONAL_TOKEN }}
```

**Node.js reusable workflow**

```yaml
name: CI-Node
on: [push, pull_request_target]
jobs:
  build:
    uses: untillpro/ci-action/.github/workflows/ci_reuse.yml@main
    secrets:
      reporeading_token: ${{ secrets.REPOREADING_TOKEN }}
```

## Architecture

- [architecture.md](architecture.md)

## Implementation

This action is implemented using **bash scripts** instead of Node.js/JavaScript:

- **Type**: Composite action (defined in `action.yml`)
- **Runtime**: Bash shell (no Node.js required)
- **Dependencies**: Standard Unix tools + GitHub CLI (for publishing)
- **Scripts**: Located in `scripts/` directory

### Main Scripts

| Script                              | Purpose                               |
|-------------------------------------|---------------------------------------|
| `ci_main.sh`                        | Main CI orchestration                 |
| `reject_hidden_folders.sh`          | Validate repository structure         |
| `detect_language.sh`                | Auto-detect Go or Node.js projects    |
| `check_source_copyright.sh`         | Validate copyright notices            |
| `check_gomod.sh`                    | Validate go.mod has no local replaces |
| `publish_release.sh`                | Create and publish GitHub releases    |
| `checkout-and-setup-go/action.yml`  | Helper composite: checkout + Go setup |

### Additional Scripts

The `scripts/` directory also contains standalone scripts for:
- `run-linters.sh` - Run golangci-lint
- `vulncheck.sh` / `execgovuln.sh` - Run govulncheck
- `check_copyright.sh` - Alternative copyright checker
- Various other utility scripts

## License

The scripts and documentation in this project are released under the [MIT License](LICENSE)
