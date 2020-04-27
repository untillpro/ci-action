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

const publishAsRelease = async function (asset, token, keep, repositoryOwner, repositoryName, targetCommitish) {
	if (!fs.existsSync(asset))
		throw { name: 'warning', message: `Asset "${asset}" is not found` }

	if (!fs.existsSync('deployer.url'))
		throw { name: 'warning', message: `File "deployer.url" missing` }

	const version = genVersion()
	const zipFile = prepareZip(asset)
	const octokit = new github.GitHub(token);

	// Create release (+tag)
	const createReleaseResponse = await octokit.repos.createRelease({
		owner: repositoryOwner,
		repo: repositoryName,
		tag_name: version,
		target_commitish: targetCommitish,
		name: version,
	})
	console.log(`Release ID: ${createReleaseResponse.data.id}`)
	console.log(`Release URL: ${createReleaseResponse.data.html_url}`)
	let result = {
		release_id: createReleaseResponse.data.id,
		release_name: createReleaseResponse.data.name,
		release_html_url: createReleaseResponse.data.html_url,
		release_upload_url: createReleaseResponse.data.upload_url,
	}

	// Upload asset
	const zipFileHeaders = {
		'content-type': 'application/zip',
		'content-length': fs.statSync(zipFile).size,
	};
	const uploadAssetResponse = await octokit.repos.uploadReleaseAsset({
		url: createReleaseResponse.data.upload_url,
		headers: zipFileHeaders,
		name: `${repositoryName}.zip`,
		data: fs.readFileSync(zipFile),
	});

	console.log(`Release asset URL: ${uploadAssetResponse.data.browser_download_url}`)
	result.asset_browser_download_url = uploadAssetResponse.data.browser_download_url

	// Upload deploy.txt
	const deployTxt = Buffer.concat([
		Buffer.from(uploadAssetResponse.data.browser_download_url + '\n'),
		fs.readFileSync('deployer.url'),
	])
	const deployTxtHeaders = {
		'content-type': 'text/plain',
		'content-length': deployTxt.length,
	};
	await octokit.repos.uploadReleaseAsset({
		url: createReleaseResponse.data.upload_url,
		headers: deployTxtHeaders,
		name: 'deploy.txt',
		data: deployTxt,
	});

	if (zipFile !== asset)
		fs.unlinkSync(zipFile)

	// get repo list
	const releases = await octokit.repos.listReleases({
		owner: repositoryOwner,
		repo: repositoryName,
	})

	// Delete old releases (with tag)
	if (keep && keep > 0)
		releases.data
			.filter(release => /^\d{8}\.\d{6}\.\d{3}$/.test(release.name)
				&& release.tag_name === release.name)
			.sort((a, b) => (b.name > a.name) ? 1 : ((a.name > b.name) ? -1 : 0))
			.slice(keep)
			.forEach(release => {
				console.log(`Delete release ${release.name}`)
				octokit.repos.deleteRelease({
					owner: repositoryOwner,
					repo: repositoryName,
					release_id: release.id,
				})
				octokit.git.deleteRef({
					owner: repositoryOwner,
					repo: repositoryName,
					ref: `tags/${release.tag_name}`,
				})
			})

	return result
}

module.exports = {
	publishAsMavenArtifact,
	publishAsRelease
}
