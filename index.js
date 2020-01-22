const core = require('@actions/core')
const github = require('@actions/github')

try {
	core.debug((new Date()).toTimeString())
	// Get the JSON webhook payload for the event that triggered the workflow
	const payload = JSON.stringify(github.context.payload, undefined, 2)
	console.log(`The event payload: ${payload}`)
	core.debug((new Date()).toTimeString())
} catch (error) {
	core.setFailed(error.message)
}
