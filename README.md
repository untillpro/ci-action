# ci-action

Continious Integration action for go- and node- projects

* Reject ".*" folders
* Reject sources which do not have "Copyright" word in first comment
* Reject sources which have LICENSE word in first comment but LICENSE file does not exist
* Reject go.mod with local replaces
* Automatically merge from develop to master (only for base repo)
  * Automatically publish artifact to Packages as Maven (group: com.github.`OWNER`, version: `DATE.TIME.mS`)
* Reject commits to master (only for base repo)
* For Go projects
  * Run `go build ./...` and `go test ./...`

## Usage

```yaml
- uses: untillpro/ci-action@master
  with:
    # Folders and files that will be ignored when checking (comma separated)
    ignore: ''

    # The name of the organization on GitHub containing private repositories
    organization: 'untillpro'

    # Auth token used to fetch dependencies from private repositories
    token: ''

    # Codecov token
    codecov_token: ''

    # File / dir name to publish
    publish-artifact: ''

    # Auth token used to publish
    publish-token: ${{ github.token }}

    # Repository name with owner. For example, untillpro/ci-action
    repository: ${{ github.repository }}
```

## Scenarios

### Go project

* Create new default branch with name "develop"
* Define branch protection rule to disable pushing to "master" branch
* Allow push access for "github-actions":

```sh
curl -u {{user}} -H "Content-Type: application/json" -X POST -d "[\"github-actions\"]" https://api.github.com/repos/{{organization}}/{{repo}}/branches/master/protection/restrictions/apps
```

* If private modules are used:
  * [Create personal access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line#creating-a-token)
  * Create secret with the received token named "REPOREADING_TOKEN"
* For automatic uploading reports to [Codecov] [Codecov](https://codecov.io/)
  * Create secret with Codecov token named "CODECOV_TOKEN"
* Create action workflow "ci.yml" with the following contents:

```yaml
name: CI-Go
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - name: Set up Go 1.13
      uses: actions/setup-go@v1
      with:
        go-version: 1.13
    - name: Checkout
      uses: actions/checkout@v2
    - name: Cache Go - Modules
      uses: actions/cache@v1
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

## Development

Development should be done in the "develop" branch.

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
