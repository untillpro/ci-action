/*
 * Copyright (c) 2020-present unTill Pro, Ltd. and Contributors
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
const core = require('@actions/core')
const github = require('@actions/github')
const rejectHiddenFolders = require('./rejectHiddenFolders')
const checkSources = require('./checkSources')

const getInputAsArray = function(name) {
	let input = core.getInput(name)
	return !input ? [] : input.split(',')
}

try {
	const expectedHiddenFolders = getInputAsArray('expectedHiddenFolders')
	const ignore = getInputAsArray('ignore')
	core.debug((new Date()).toTimeString())
	console.log('Reject ".*" folders')
	rejectHiddenFolders(expectedHiddenFolders)
	core.debug((new Date()).toTimeString())
	console.log('Reject sources which do not have "Copyright" word in first comment')
	checkSources.rejectSourcesWithoutCopyright(ignore)
	core.debug((new Date()).toTimeString())
	// Get the JSON webhook payload for the event that triggered the workflow
	const payload = JSON.stringify(github.context.payload, undefined, 2)
	console.log(`The event payload: ${payload}`)
	core.debug((new Date()).toTimeString())
} catch (error) {
	core.setFailed(error.message)
}
