# ci-action

Continious Integration action for go- and node- projects

* Reject ".*" folders
* Reject sources which do not have "Copyright" word in first comment
* TODO: Reject sources which have LICENSE word in first comment but LICENSE file does not exist
* TODO: Reject go.mod with local replaces
* TODO: Automatically merge from develop to master
* TODO: Reject commits to master
* For Go projects
  * Run `go build ./...` and `go test ./...`
