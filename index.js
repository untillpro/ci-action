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
		const organization = core.getInput('organization')
		const token = core.getInput('token')

		let branchName = github.context.ref
		if (branchName && branchName.indexOf('refs/heads/') > -1)
			branchName = branchName.slice('refs/heads/'.length)

		// Reject commits to master
		if (branchName === 'master')
			throw { name: 'warning', message: 'Unexpected commit to master branch'}

		// Reject ".*" folders
		rejectHiddenFolders(expectedHiddenFolders)

		// Reject sources which do not have "Copyright" word in first comment
		checkSources.rejectSourcesWithoutCopyright(ignore)

		// Get the JSON webhook context
		const context = JSON.stringify(github.context, undefined, 2)
		console.log(`The event context: ${context}`)

		let language = checkSources.detectLanguage()
		if (language === "go") {
			core.info('Go project detected')
			process.env.GOPRIVATE = (process.env.GOPRIVATE ? process.env.GOPRIVATE + ',' : '') + `github.com/${organization}/*`
			if (token) {
				await execute(`git config --global url."https://${token}:x-oauth-basic@github.com/${organization}".insteadOf "https://github.com/${organization}"`)
			}
			await execute('go build ./...')
			await execute('go test ./...')
		}

		// Automatically merge from develop to master
		if (branchName === 'develop') {
			core.info('Merge to master')
			await execute(`git fetch --unshallow`)
			await execute(`git fetch origin master`)
			await execute(`git checkout master`)
			await execute(`git merge ${github.context.sha}`)
			await execute(`git push`)
		}

	} catch (error) {
		if (error.name !== 'warning') {
			console.error(error)
		}
		core.setFailed(error.message)
	}
}

run()
