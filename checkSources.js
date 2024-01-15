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
/*
    if (fs.existsSync('go.mod')) return "go"
    let sourceFiles = getSourceFiles('.', ignore)
    for (const file of sourceFiles) {
        if (path.extname(file) === ".go") return "go"
        if (/\.[jt]sx?/.test(path.extname(file))) return "node_js"
    }
    return "unknown"
*/
	let sourceFiles = getSourceFiles('.', ignore)
	if (fs.existsSync('go.mod')) return "go"
	sourceFiles.forEach(file => {
		if (path.extname(file) === ".go") return "go"
	})
	sourceFiles.forEach(file => {
		if (path.extname(file) === ".js") return "node_js"
	})
	return "unknown"

}


const getFirstComment = function (file) {
	let content = fs.readFileSync(file, 'utf8')
	let m = content.match(/^(\s|\/\/[^\n]*\n|\/\*([^*]|\*(?!\/))*\*\/)*/)
	return m !== null && m.length > 0 ? m[0] : null
}

const checkFirstCommentInSources = function (ignore, ignoreCopyright) {
	let rejectSourcesWhichHaveLicenseWord = !fs.existsSync('LICENSE')
	let sourceFiles = getSourceFiles('.', ignore)
	sourceFiles.forEach(file => {
		let firstComment = getFirstComment(file)
		if (firstComment !== null && /\bDO NOT EDIT\b/.test(firstComment))
			return // continue
		if (!ignoreCopyright && (firstComment === null || !/\bCopyright\b/.test(firstComment)))
			throw new Error(`Missing Copyright in first comment in file: "${file}"`)
		if (rejectSourcesWhichHaveLicenseWord && /\bLICENSE\b/.test(firstComment))
			throw new Error(`LICENSE file does not exist but first comment has LICENSE word in file: "${file}"`)
	})
}

const checkGoMod = function () {
	if (!fs.existsSync('go.mod')) return
	let goMod = fs.readFileSync('go.mod', 'utf8')
	let matches = goMod.matchAll(/^\s*replace\s+(.*?)\s*=>\s*(.*?)\s*$/gm);
	for (const match of matches) {
		if (match[2].startsWith('.') || match[2].startsWith('/') || match[2].startsWith('\\'))
			throw new Error(`The file go.mod contains a local replace: ${match[0].trim()}`)
	}
}

module.exports = {
	getSourceFiles,
	detectLanguage,
	checkFirstCommentInSources,
	checkGoMod
}
