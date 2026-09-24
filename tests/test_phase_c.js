// Phase C picker keyboard contract. Runtime focus and key delivery remain live-tested.
const Logic = require('./load_logic')
const boundedIndex = Logic.boundedIndex
const indexForAddress = Logic.indexForAddress

let passed = 0
let failed = 0
function assert(condition, message) {
  if (condition) passed++
  else { failed++; console.error('FAIL: ' + message) }
}

const entries = [
  { address: 'aaa', title: 'Terminal', appId: 'foot' },
  { address: 'bbb', title: 'Browser', appId: 'firefox' },
  { address: 'ccc', title: 'Editor', appId: 'nvim' }
]
const count = entries.length

assert(boundedIndex(-1, 0) === -1, 'empty list keeps -1')
assert(boundedIndex(0, 0) === -1, 'empty list rejects index 0')
assert(boundedIndex(3, 0) === -1, 'empty list rejects a stale index')

assert(boundedIndex(-1, count) === 0, 'no prior selection falls back to the first source')
assert(indexForAddress(entries, '') === -1, 'empty selected address matches nothing')
assert(boundedIndex(indexForAddress(entries, ''), count) === 0, 'first open selects the first source')

assert(indexForAddress(entries, 'bbb') === 1, 'selected address resolves to its index')
assert(indexForAddress(entries, '0xBBB') === 1, '0x-prefixed selected address resolves')
assert(boundedIndex(indexForAddress(entries, 'bbb'), count) === 1, 'reopen restores the previously selected source')

assert(boundedIndex(0 + 1, count) === 1, 'Down from the first source moves to the second')
assert(boundedIndex(1 + 1, count) === 2, 'Down from the middle moves to the last')

assert(boundedIndex(2 - 1, count) === 1, 'Up from the last source moves back')
assert(boundedIndex(1 - 1, count) === 0, 'Up from the second source returns to the first')

assert(boundedIndex(2 + 1, count) === 2, 'Down at the last source clamps instead of wrapping')
assert(boundedIndex(99, count) === 2, 'a stale high index clamps to the last source')

assert(boundedIndex(0 - 1, count) === 0, 'Up at the first source clamps instead of wrapping')
assert(boundedIndex(-1, count) === 0, 'a negative index clamps to the first source')

assert(boundedIndex(0, count) === 0, 'Home selects the first source')
assert(boundedIndex(count - 1, count) === 2, 'End selects the last source')
assert(boundedIndex(count - 1, 0) === -1, 'End on an empty list selects nothing')

assert(boundedIndex(2, 2) === 1, 'index is repaired after the last source disappears')
assert(boundedIndex(5, 1) === 0, 'stale index repairs to the only remaining source')
assert(boundedIndex(0, 0) === -1, 'index resets to -1 when the list empties')

const remaining = entries.slice(0, 2)
assert(indexForAddress(remaining, 'ccc') === -1, 'a removed source is not found')
assert(boundedIndex(indexForAddress(remaining, 'ccc'), remaining.length) === 0,
  'the picker falls back to the first source after the selection disappears')
assert(indexForAddress(remaining, 'Editor') === -1, 'a title never matches an address')
assert(indexForAddress([{ address: '', title: 'Editor', appId: 'nvim' }], '0ccc') === -1,
  'a blank address never matches')

// source removal / current index repair: the keyboard anchor is re-resolved
const shifted = [{ address: 'bbb', title: 'Browser', appId: 'firefox' },
  { address: 'aaa', title: 'Terminal', appId: 'foot' },
  { address: 'ccc', title: 'Editor', appId: 'nvim' }]
const repairedIndex = Logic.repairedIndex
assert(repairedIndex(0, 'ccc', shifted) === 2, 'repair follows the keyboard window after the list shifts')
assert(repairedIndex(1, 'bbb', entries) === 1, 'repair keeps an anchor still in place')
assert(repairedIndex(1, 'zzz', entries) === 1, 'repair keeps a valid position when the anchor is gone')
assert(repairedIndex(5, 'zzz', entries) === 2, 'repair clamps a stale index when the anchor is gone')
assert(repairedIndex(2, '', entries) === 2, 'repair ignores an empty anchor')
assert(repairedIndex(2, 'aaa', []) === -1, 'repair selects nothing on an empty list')
assert(repairedIndex(5, '', []) === -1, 'repair selects nothing on an empty list even when stale')

let inBounds = true
let index = boundedIndex(indexForAddress(entries, ''), count)
for (let i = 0; i < 50; i++) {
  index = boundedIndex(index + (i % 3 === 2 ? -1 : 1), count)
  if (index < 0 || index >= count) inBounds = false
}
assert(inBounds, 'a mixed Up/Down walk never leaves the list bounds')

console.log('\n' + passed + ' passed, ' + failed + ' failed')
if (failed > 0) process.exit(1)
