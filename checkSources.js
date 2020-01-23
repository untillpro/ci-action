/*
 * Copyright (c) 2020-present unTill Pro, Ltd. and Contributors
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
const fs = require('fs')
const path = require('path')

const getSourceFiles = function (dir, files_) {
	files_ = files_ || []
	let files = fs.readdirSync(dir)
	for (let i in files) {
		let name = dir + '/' + files[i]
		if (fs.statSync(name).isDirectory()) {
			if (name.charAt(0) !== '.')
				getFiles(name, files_)
		} else {
			if (['.go', '.js'].includes(path.extname(name)))
				files_.push(name)
		}
	}
	return files_
}

const getFirstComment = function (file) {
	let content = fs.readFileSync(file, 'utf8')
	let m = content.match(/^(\s|\/\/[^\n]*\n|\/\*([^*]|\*(?!\/))*\*\/)*/)
	return m !== null && m.length > 0 ? m[0] : null
}

const rejectSourcesWithoutCopyright = function () {
	let sourceFiles = getSourceFiles('.')
	sourceFiles.forEach(file => {
		let firstComment = getFirstComment(file)
		if (firstComment === null || !firstComment.includes("Copyright"))
			throw new Error(`Missing Copyright in first comment in file: "${file}"`)
	})
}

module.exports = {
	getSourceFiles,
	rejectSourcesWithoutCopyright
}
