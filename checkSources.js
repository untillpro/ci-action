/*
 * Copyright (c) 2020-present unTill Pro, Ltd. and Contributors
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
const fs = require('fs')
const path = require('path')

const getSourceFiles = function (dir, ignore, files_) {
	ignore = ignore || []
	files_ = files_ || []
	let files = fs.readdirSync(dir)
	for (let i in files) {
		let fileName = files[i]
		if (fileName.charAt(0) === '.') continue
		let filePath = path.join(dir, fileName)
		if (ignore.includes(filePath) || ignore.includes(filePath.replace(/\\/g, '/'))) continue
		if (fs.statSync(filePath).isDirectory()) {
			getSourceFiles(filePath, ignore, files_)
		} else {
			if (['.go', '.js'].includes(path.extname(fileName)))
				files_.push(filePath)
		}
	}
	return files_
}

const detectLanguage = function (ignore) {
	let sourceFiles = getSourceFiles('.', ignore)
	if (fs.existsSync('go.mod')) return "go"
	sourceFiles.forEach(file => {
		if (path.extname(file) === ".go") return "go"
	})
	sourceFiles.forEach(file => {
		if (path.extname(file) === ".js") return "js"
	})
	return "unknown"
}

const getFirstComment = function (file) {
	let content = fs.readFileSync(file, 'utf8')
	let m = content.match(/^(\s|\/\/[^\n]*\n|\/\*([^*]|\*(?!\/))*\*\/)*/)
	return m !== null && m.length > 0 ? m[0] : null
}

const rejectSourcesWithoutCopyright = function (ignore) {
	let sourceFiles = getSourceFiles('.', ignore)
	sourceFiles.forEach(file => {
		let firstComment = getFirstComment(file)
		if (firstComment === null || !firstComment.includes("Copyright"))
			throw { name: 'warning', message: `Missing Copyright in first comment in file: "${file}"` }
	})
}

module.exports = {
	getSourceFiles,
	detectLanguage,
	rejectSourcesWithoutCopyright
}
