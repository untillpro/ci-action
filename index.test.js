/*
 * Copyright (c) 2020-present unTill Pro, Ltd. and Contributors
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
const cp = require('child_process')
const path = require('path')
const rejectHiddenFolders = require('./rejectHiddenFolders')
const checkSources = require('./checkSources')

test('test runs', () => {
	const ip = path.join(__dirname, 'index.js')
	let env = Object.assign({}, process.env)
	env.INPUT_IGNORE = 'dist,node_modules'
	console.log(cp.execSync(`node ${ip}`, { env: env }).toString())
})

test('test rejectHiddenFolders', () => {
	rejectHiddenFolders()
})

test('test checkSources', () => {
	checkSources.checkFirstCommentInSources(['dist', 'node_modules'])
})
