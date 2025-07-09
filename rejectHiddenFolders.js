/*
 * Copyright (c) 2020-present unTill Pro, Ltd. and Contributors
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
const { readdirSync } = require('fs')

const getSubFolders = source =>
	readdirSync(source, { withFileTypes: true })
		.filter(dirent => dirent.isDirectory())
		.map(dirent => dirent.name)

let rejectHiddenFolders = function (ignore) {
	getSubFolders(".").forEach(folder => {
		if (folder.charAt(0) == '.' && folder != ".git" && folder != ".github" && folder != ".husky" && folder != ".augment") {
			if (!ignore.includes(folder))
				throw new Error(`Unexpected hidden folder: "${folder}"`)
		}
	})
}

module.exports = rejectHiddenFolders
