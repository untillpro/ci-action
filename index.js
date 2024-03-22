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
	return !input ? [] : input.split(',').map(it => it.trim())
}

async function run() {
	try {
		const ignore = getInputAsArray('ignore')
		const organization = getInputAsArray('organization')
		const token = core.getInput('token')
		const codecovToken = core.getInput('codecov-token')
		const codecovGoRace = core.getInput ('codecov-go-race') === 'true'
		const publishAsset = core.getInput('publish-asset')
		const publishToken = core.getInput('publish-token')
		const publishKeep = core.getInput('publish-keep')
		const repository = core.getInput('repository')
		const runModTidy = core.getInput('run-mod-tidy') === 'true'
		const mainBranch = core.getInput('main-branch')
		const ignoreCopyright = core.getInput('ignore-copyright') === 'true'
		const ignoreRunBuild = core.getInput('ignore-build') === 'true'
		const testfolder = core.getInput('test-folder')
		const shorttest = core.getInput ('short-test') === 'true'

		const repositoryOwner = repository.split('/')[0] ||
			github.context.payload && github.context.payload.repository && github.context.payload.repository.owner && github.context.payload.repository.owner.login
		const repositoryName = repository && repository.split('/')[1] ||
			github.context.payload && github.context.payload.repository && github.context.payload.repository.name

		const isNotFork = github.context.payload && github.context.payload.repository && !github.context.payload.repository.fork

		let branchName = github.context.ref
		if (branchName && branchName.indexOf('refs/heads/') > -1)
			branchName = branchName.slice('refs/heads/'.length)

		// // Print githubJson
		// core.startGroup("githubJson")
		// const githubJson = JSON.stringify(github, undefined, 2)
		// core.info(githubJson)
		// core.endGroup()

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
		checkSources.checkFirstCommentInSources(ignore, ignoreCopyright)

		let language = checkSources.detectLanguage()
		if (language === "go") {
			core.info('Go project detected')

			// Reject go.mod with local replaces
			checkSources.checkGoMod()

			// Build
			core.startGroup('Build')
			try {
				for (const i in organization) {
					process.env.GOPRIVATE = (process.env.GOPRIVATE ? process.env.GOPRIVATE + ',' : '') + `github.com/${organization[i]}/*`
					if (token) {
						await execute(`git config --global url."https://${token}:x-oauth-basic@github.com/${organization[i]}".insteadOf "https://github.com/${organization[i]}"`)
					}
				}

				if (testfolder.length != 0) {
					await execute('cd ' + testfolder)
				}

				if (!ignoreRunBuild) {
					await execute('go build ./...')
				}

				if (runModTidy) {
					await execute('go mod tidy')
				}

				// run Codecov / test
				if (codecovToken) {
					core.startGroup('Codecov')
					await execute('go install github.com/heeus/gocov@latest')
					let tststr=''
/*					
					if (codecovGoRace)
						tststr='gocov -t="-race -covermode=atomic" -v'
					else
						tststr='gocov -t="-covermode=atomic" -v'
*/						
						
					if (codecovGoRace)
						tststr = 'go test ./... -race -coverprofile=coverage.txt -covermode=atomic -coverpkg=./...'
					else
						tststr ='go test ./... -coverprofile=coverage.txt -covermode=atomic -coverpkg=./...'
						
					if (shorttest){
						tststr=tststr + ' -short'
						tststr ='go test ./... -coverprofile=coverage.txt -covermode=atomic -coverpkg=./...'
					}
					await execute(tststr)
					core.endGroup()
					await execute(`bash -c "bash <(curl -Os https://uploader.codecov.io/latest/linux/codecov) -t ${codecovToken}"`)
				} else {
					let tststr='go test ./...'
					if (shorttest){
						tststr=tststr + ' -short'
					}
					await execute(tststr)
				}
				if (testfolder.length != 0) {
					await execute('cd .')
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

		let publishResult = null

		// Publish asset
		if (branchName === mainBranch && publishAsset) {
			core.startGroup("Publish")
			try {
				publishResult = await publish.publishAsRelease(publishAsset, publishToken, publishKeep, repositoryOwner, repositoryName, github.context.sha)
			} finally {
				core.endGroup()
			}
		}

		if (publishResult !== null)
			for (const name in publishResult)
				core.setOutput(name, `${publishResult[name] || ''}`)

	} catch (error) {
		core.setFailed(error.message)
	}
}

run()
