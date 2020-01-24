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
const util = require('util')
const exec = util.promisify(require('child_process').exec)

async function execute(command) {
	console.log(`$ ${command}`)
	const { stdout, stderr } = await exec(command)
	if (stdout) console.log(stdout)
	if (stderr) console.log(stderr)
}

const getInputAsArray = function (name) {
	let input = core.getInput(name)
	return !input ? [] : input.split(',')
}

async function run() {
	try {
		const expectedHiddenFolders = getInputAsArray('expectedHiddenFolders')
		const ignore = getInputAsArray('ignore')

		let branchName = github.context.ref
		if (branchName.indexOf('refs/heads/') > -1)
			branchName = branchName.slice('refs/heads/'.length)

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
		const github_json = JSON.stringify(github, undefined, 2)
		console.log(`The event github_json: ${github_json}`)

		let language = checkSources.detectLanguage()
		if (language === "go") {
			core.info('Go project detected')
			process.env.GOPRIVATE = (process.env.GOPRIVATE ? process.env.GOPRIVATE + ',' : '') + 'github.com/untillpro'
			if (process.env.GITHUB_TOKEN) {
				await execute(`git config --global url."https://${process.env.GITHUB_TOKEN}:x-oauth-basic@github.com/untillpro".insteadOf "https://github.com/untillpro"`)
			}
			await execute('go build ./...')
			await execute('go test ./...')
		}

		if (branchName === 'develop') {
			core.info('Merge to master')
			await execute(`git fetch origin master`)
			await execute(`git checkout master`)
			await execute(`git merge ${github.sha}`)
			await execute(`git push 2>&1`)
		}

	} catch (error) {
		console.error(error);
		core.setFailed(error.message)
	}
}

run()
