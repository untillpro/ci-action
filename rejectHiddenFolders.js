const { readdirSync } = require('fs')

const getSubFolders = source =>
	readdirSync(source, { withFileTypes: true })
		.filter(dirent => dirent.isDirectory())
		.map(dirent => dirent.name)

let rejectHiddenFolders = function (expectedHiddenFolders) {
	var expectedHiddenFoldersArray = expectedHiddenFolders.split(',')
	getSubFolders(".").forEach(folder => {
		if (folder.charAt(0) == '.' && folder != ".git" && folder != ".github") {
			if (!expectedHiddenFoldersArray.includes(folder))
				throw new Error(`Unexpected hidden folder: "${folder}"`)
		}
	})
}

module.exports = rejectHiddenFolders
