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

const publish = async function (artifact, token, organization, repositoryName) {
	// TODO rename publish_file to artifact
	if (!fs.existsSync(artifact))
		throw { name: 'warning', message: `Artifact "${artifact}" is not found` }

	// prepare artifactFile
	let artifactFile = artifact
	let zipped = false
	const isDir = fs.lstatSync(artifact).isDirectory()
	if (isDir || !path.extname(artifact)) {
		var zip = new admzip()
		if (isDir)
			zip.addLocalFolder(artifact)
		else
			zip.addLocalFile(artifact)
		artifactFile = tmp.tmpNameSync({ postfix: '.zip' })
		zip.writeZip(artifactFile)
		zipped = true
	}
	console.log(`artifactFile: ${artifactFile}`)

	// TODO: Remove Artifact if is exists

	// TODO: Publish Artifact to: package = com.github.${organization}, version = master-SNAPSHOT
	await execute(`mvn deploy:deploy-file --batch-mode -DgroupId=com.github.${organization} \
-DartifactId=${repositoryName} -Dversion=master-SNAPSHOT -DgeneratePom=true \
-DrepositoryId=GitHubPackages -Durl=https://x-oauth-basic:${token}@maven.pkg.github.com/${organization}/${repositoryName} -Dfile="${artifactFile}"`)

	// TODO: ...

	// remove temporary file
	if (zipped)
		fs.unlinkSync(artifactFile)
}

module.exports = publish