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
		const publishAsset = core.getInput('publish-asset')
		const publishToken = core.getInput('publish-token')
		const publishKeep = core.getInput('publish-keep')
		const repository = core.getInput('repository')

		const repositoryOwner = repository.split('/')[0] ||
			github.context.payload && github.context.payload.repository && github.context.payload.repository.owner && github.context.payload.repository.owner.login
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
		//core.info(`github.context.repo: ${github.context.repo}`)
		core.info(`repository: ${repository}`)
		core.info(`organization: ${organization}`)
		core.info(`repositoryOwner: ${repositoryOwner}`)
		core.info(`repositoryName: ${repositoryName}`)
		core.info(`actor: ${github.context.actor}`)
		core.info(`eventName: ${github.context.eventName}`)
		core.info(`isNotFork: ${isNotFork}`)
		core.info(`branchName: ${branchName}`)
		core.endGroup()

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
			core.startGroup('Build')
			try {
				process.env.GOPRIVATE = (process.env.GOPRIVATE ? process.env.GOPRIVATE + ',' : '') + `github.com/${organization}/*`
				if (token) {
					await execute(`git config --global url."https://${token}:x-oauth-basic@github.com/${organization}".insteadOf "https://github.com/${organization}"`)
				}
				await execute('go build ./...')

				// run Codecov / test
				if (codecovToken) {
					await execute('go test ./... -race -coverprofile=coverage.txt -covermode=atomic')
					core.endGroup()
					core.startGroup('Codecov')
					await execute(`bash -c "bash <(curl -s https://codecov.io/bash) -t ${codecovToken}"`)
				} else {
					await execute('go test ./...')
				}
			} finally {
				core.endGroup()
			}

		} if (language === "node_js") {
			core.info('Node.js project detected')

			// Build
			core.startGroup('Build')
			try {
				await execute('npm install')
				await execute('npm run build --if-present')
				await execute('npm test')

				// run Codecov
				if (codecovToken) {
					core.endGroup()
					core.startGroup('Codecov')
					await execute('npm install -g codecov')
					await execute('istanbul cover ./node_modules/mocha/bin/_mocha --reporter lcovonly -- -R spec')
					await execute(`codecov --token=${codecovToken}`)
				}
			} finally {
				core.endGroup()
			}
		}

		let result = null

		// Publish asset
		if (branchName === 'master' && publishAsset) {
			core.startGroup("Publish")
			try {
				result = await publish.publishAsRelease(publishAsset, publishToken, publishKeep, repositoryOwner, repositoryName, github.context.sha)
			} finally {
				core.endGroup()
			}
		}

		if (result !== null) {
			for (const name in result) {
				core.warning(name + ': ' + result[name])
				core.setOutput(name, result[name])
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
