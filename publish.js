/*
 * Copyright (c) 2020-present unTill Pro, Ltd. and Contributors
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
const fs = require('fs')
const path = require('path')
const tmp = require('tmp');
var admzip = require('adm-zip');
const execute = require('./common').execute
//const core = require('@actions/core')
const github = require('@actions/github')

function genVersion() {
	// UTC date-time as yyyyMMdd.HHmmss.SSS
	return new Date().toISOString().replace(/T/, '.').replace(/-|:|Z/g, '')
}

function prepareZip(source) {
	let zipFile = source
	const isDir = fs.lstatSync(source).isDirectory()
	if (isDir || path.extname(source) !== '.zip') {
		var zip = new admzip()
		if (isDir)
			zip.addLocalFolder(source)
		else
			zip.addLocalFile(source)
		zipFile = tmp.tmpNameSync({ postfix: '.zip' })
		zip.writeZip(zipFile)
	}
	return zipFile
}

const publishAsMavenArtifact = async function (artifact, token, repositoryOwner, repositoryName) {
	if (!fs.existsSync(artifact))
		throw { name: 'warning', message: `Artifact "${artifact}" is not found` }

	const zipFile = prepareZip(artifact)

	const version = genVersion()

	// Publish artifact to: com.github.${repositoryOwner}:${repositoryName}:${version}:zip
	await execute(`mvn deploy:deploy-file --batch-mode -DgroupId=com.github.${repositoryOwner} \
-DartifactId=${repositoryName} -Dversion=${version} -DgeneratePom=true \
-DrepositoryId=GitHubPackages -Durl=https://x-oauth-basic:${token}@maven.pkg.github.com/${repositoryOwner}/${repositoryName} -Dfile="${zipFile}"`)

	if (zipFile !== artifact)
		fs.unlinkSync(zipFile)
}

const publishAsRelease = async function (asset, token, repositoryOwner, repositoryName) {
	if (!fs.existsSync(asset))
		throw { name: 'warning', message: `Asset "${asset}" is not found` }

	const version = genVersion()
	const zipFile = prepareZip(asset)
	const octokit = new github.GitHub(token);

	// Create tag
	await execute(`git tag ${version}`)
	await execute(`git push origin ${version}`)

	// Create release
	const createReleaseResponse = await octokit.repos.createRelease({
		owner: repositoryOwner,
		repo: repositoryName,
		tag_name: version,
		name: version,
	})
	console.log(`createReleaseResponse.data.id: ${createReleaseResponse.data.id}`)
	console.log(`createReleaseResponse.data.html_url: ${createReleaseResponse.data.html_url}`)
	console.log(`createReleaseResponse.data.upload_url: ${createReleaseResponse.data.upload_url}`)

	// TODO use target_commitish

	// TODO Append asset

	if (zipFile !== asset)
		fs.unlinkSync(zipFile)

	// TODO Additionaly:
	// TODO Remove old releases
	// TODO Remove old tags
}

module.exports = {
	publishAsMavenArtifact,
	publishAsRelease
}
