# Sparsesets for Nim

```nim
var s = initSparseSet[uint16, int](128) # capacity of sparse and dense data
assert s.len == 0
let ent1 = 1'u16
let ent2 = 2'u16
s[ent1] = 5
s[ent2] = 4
assert(s.len == 2)
s.sort(cmp)
s[ent1] = 5
s[ent2] = 4
```
