/*
 * Copyright (c) 2020-present unTill Pro, Ltd. and Contributors
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
const cp = require('child_process')
const path = require('path')
const checkSources = require('./checkSources')

test('test runs', () => {
    const ip = path.join(__dirname, 'index.js')
    console.log(cp.execSync(`node ${ip}`).toString())
})

test('test checkSources', () => {
	console.log(checkSources.rejectSourcesWithoutCopyright())
})