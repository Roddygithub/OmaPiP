const fs = require('fs')
const vm = require('vm')

const source = fs.readFileSync(require.resolve('../PanelLogic.js'), 'utf8')
  .replace(/^\.pragma library\s*\n/, '')
const context = {}
vm.runInNewContext(source + '\nthis.logic = { normalizeAddress, isCapturableSource, indexForAddress, boundedNumber, boundedIndex, repairedIndex, displaySize, initialViewerSize }', context)
module.exports = context.logic
