/*
 * Copyright (c) 2020-present unTill Pro, Ltd. and Contributors
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
const core = require('@actions/core')
const github = require('@actions/github')
const execute = require('./common').execute
const rejectHiddenFolders = require('./rejectHiddenFolders')
const checkSources = require('./checkSources')
const publish = require('./publish')

const getInputAsArray = function (name) {
	let input = core.getInput(name)
	return !input ? [] : input.split(',')
}

async function run() {
	try {
		const ignore = getInputAsArray('ignore')
		const organization = core.getInput('organization')
		const token = core.getInput('token')
		const codecovToken = core.getInput('codecov-token')
		const publishArtifact = core.getInput('publish-artifact')
		const publishToken = core.getInput('publish-token')
		const repository = core.getInput('repository')

		const repositoryOwner = repository.split('/')[0]
		const repositoryName = repository && repository.split('/')[1] ||
			github.context.payload && github.context.payload.repository && github.context.payload.repository.name

		const isNotFork = github.context.payload && github.context.payload.repository && !github.context.payload.repository.fork

		let branchName = github.context.ref
		if (branchName && branchName.indexOf('refs/heads/') > -1)
			branchName = branchName.slice('refs/heads/'.length)

		// Print githubJson
		core.startGroup("githubJson")
		const githubJson = JSON.stringify(github, undefined, 2)
		core.info(githubJson)
		core.endGroup()

		// Print data from webhook context
		core.startGroup("Context")
		core.info(`github.repository: ${github.repository}`)
		core.info(`github.token: ${github.token}`)
		core.info(`repository: ${repository}`)
		core.info(`organization: ${organization}`)
		core.info(`repositoryName: ${repositoryName}`)
		core.info(`actor: ${github.context.actor}`)
		core.info(`eventName: ${github.context.eventName}`)
		core.info(`isNotFork: ${isNotFork}`)
		core.info(`branchName: ${branchName}`)
		core.endGroup()

		// Reject commits to master
		if (isNotFork && branchName === 'master')
			throw { name: 'warning', message: 'Unexpected commit to master branch' }

		// Reject ".*" folders
		rejectHiddenFolders(ignore)

		// Reject sources which do not have "Copyright" word in first comment
		// Reject sources which have LICENSE word in first comment but LICENSE file does not exist
		checkSources.checkFirstCommentInSources(ignore)

		let language = checkSources.detectLanguage()
		if (language === "go") {
			core.info('Go project detected')

			// Reject go.mod with local replaces
			checkSources.checkGoMod()

			// Build
			process.env.GOPRIVATE = (process.env.GOPRIVATE ? process.env.GOPRIVATE + ',' : '') + `github.com/${organization}/*`
			if (token) {
				await execute(`git config --global url."https://${token}:x-oauth-basic@github.com/${organization}".insteadOf "https://github.com/${organization}"`)
			}
			await execute('go build ./...')

			// run Codecov / test
			if (codecovToken) {
				await execute('go test ./... -race -coverprofile=coverage.txt -covermode=atomic')
				core.startGroup('Codecov')
				try {
					await execute(`bash -c "bash <(curl -s https://codecov.io/bash) -t ${codecovToken}"`)
				} finally {
					core.endGroup()
				}
			} else {
				await execute('go test ./...')
			}
		}

		// Publish and automatically merge from develop to master
		if (isNotFork && branchName === 'develop') {

			if (publishArtifact) {
				core.startGroup("Publish")
				try {
					await publish(publishArtifact, publishToken, repositoryOwner, repositoryName)
				} finally {
					core.endGroup()
				}
			}

			core.startGroup('Merge to master')
			try {
				await execute(`git fetch --prune --unshallow`)
				await execute(`git fetch origin master`)
				await execute(`git checkout master`)
				await execute(`git merge ${github.context.sha}`)
				await execute(`git push`)
			} finally {
				core.endGroup()
			}

		}

	} catch (error) {
		if (error.name !== 'warning') {
			console.error(error)
		}
		core.setFailed(error.message)
	}
}

run()
