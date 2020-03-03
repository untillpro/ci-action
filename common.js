/*
 * Copyright (c) 2020-present unTill Pro, Ltd. and Contributors
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
const util = require('util')
const exec = util.promisify(require('child_process').exec)

const execute = async function (command) {
	console.log(`[command]${command}`)
	const { stdout, stderr } = await exec(command)
	if (stdout) console.log(stdout)
	if (stderr) console.log(stderr)
}

module.exports = {
	execute
}
