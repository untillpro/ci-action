# ci-action

Continuous Integration action for go- and node- projects

* Reject ".*" folders (except `ignore` folders)
* For sources, except `ignore` and first comments which include `DO NOT EDIT`:
  * Reject sources which do not have "Copyright" word in first comment
  * Reject sources which have LICENSE word in first comment but LICENSE file does not exist
* Reject go.mod with local replaces
* For Go projects
  * Run `go build ./...` and `go test ./...`
  * Run linting with golangci-lint
  * Run vulnerability checks with govulncheck
* For Node.js projects
  * Run `npm install`, `npm run build --if-present` and `npm test`
* Publish Release (only for "master" branch if `publish-asset` property is set)
  * The `deployer.url` file must be present in the root of the repository

## Usage

```yaml
- uses: untillpro/ci-action@master
  with:
    # Folders and files that will be ignored when checking (comma separated)
    ignore: ''

    # The name of the organization(s) on GitHub containing private repositories (comma separated)
    organization: 'untillpro'

    # Auth token used to fetch dependencies from private repositories
    token: ''

    # Codecov token
    codecov-token: ''

    # Codecov: use Go Race Detector
    codecov-go-race: true

    # Ignore go build step
    ignore-build: false

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
    - name: Set up Go
      uses: actions/setup-go@v5
      with:
        go-version: '1.24'
        cache: false
    - name: Checkout
      uses: actions/checkout@v4
    - name: Cache Go - Modules
      uses: actions/cache@v4
      with:
        path: ~/go/pkg/mod
        key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
        restore-keys: |
          ${{ runner.os }}-go-
    - name: CI
      uses: untillpro/ci-action@master
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
    - name: Set up Go
      uses: actions/setup-go@v5
      with:
        go-version: '1.24'
        cache: false
    - name: Install TinyGo
      run: |
        wget https://github.com/tinygo-org/tinygo/releases/download/v0.37.0/tinygo_0.37.0_amd64.deb
        sudo dpkg -i tinygo_0.37.0_amd64.deb
    - name: Checkout
      uses: actions/checkout@v4
    - name: CI
      uses: untillpro/ci-action@master
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
      uses: untillpro/ci-action@master
      with:
        codecov-token: ${{ secrets.CODECOV_TOKEN }}
```

## Architecture

- [architecture.md](architecture.md)

## Development

Install the dependencies

```sh
npm install
```

Run the tests

```sh
npm test
```

Run package

```sh
npm run package
```

## License

The scripts and documentation in this project are released under the [MIT License](LICENSE)
