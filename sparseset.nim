import std / algorithm
from typetraits import supportsCopyMem

type
  Entry*[K, V] = tuple
    key: K
    value: V
  SparseSet*[K, V] = object ## K must be an Integer type
    len: int
    sparse: seq[K]          ## Mapping from sparse handles to dense values.
    dense: seq[Entry[K, V]] ## Mapping from dense values to sparse handles.

template empty*[K](key: K): K = high(K)
template empty*[K](t: typedesc[K]): K = high(t)

proc initSparseSet*[K, V](cap: Natural): SparseSet[K, V] =
  result = SparseSet[K, V](dense: newSeq[Entry[K, V]](cap), sparse: newSeq[K](cap))
  var k: K
  result.sparse.fill(empty(k))

proc contains*[K, V](s: SparseSet[K, V], key: K): bool =
  ## Returns true if the sparse is registered to a dense index.
  key.int < s.sparse.len and s.sparse[key.int] != empty(key)

proc `[]=`*[K, V](s: var SparseSet[K, V], key: K, value: sink V) =
  ## Inserts a `(key, value)` pair into `s`.
  assert int(key) < s.sparse.len, "key must be under len of SparseSet"
  var denseIndex = s.sparse[key.int]
  if denseIndex == empty(key):
    denseIndex = K(s.len)
    s.dense[denseIndex.int].key = key
    s.sparse[key.int] = denseIndex
    inc(s.len)
  s.dense[denseIndex.int].value = value

template get(s, key) =
  if key notin s:
    raise newException(KeyError, "key not in SparseSet")
  result = s.dense[s.sparse[key.int].int].value

proc `[]`*[K, V](s: var SparseSet[K, V], key: K): var V =
  ## Retrieves the value at `s[key]`. The value can be modified.
  ## If `key` is not in `s`, the `KeyError` exception is raised.
  get(s, key)

proc `[]`*[K, V](s: SparseSet[K, V], key: K): lent V =
  ## Retrieves the value at `s[key]`.
  ## If `key` is not in `s`, the `KeyError` exception is raised.
  get(s, key)

proc del*[K, V](s: var SparseSet[K, V], key: K) =
  ## Deletes `key` from sparse set `s`. Does nothing if the key does not exist.
  let denseIndex = s.sparse[key.int]
  if denseIndex != empty(key):
    let lastIndex = s.len - 1
    let lastKey = s.dense[lastIndex].key
    s.sparse[lastKey.int] = denseIndex
    s.sparse[key.int] = empty(key)
    s.dense[denseIndex.int] = move(s.dense[lastIndex])
    s.len.dec

proc sort*[K, V](s: var SparseSet[K, V], cmp: proc (x, y: V): int, order = SortOrder.Ascending) =
  for i in 1 ..< s.len:
    let x = move(s.dense[i].value)
    let xKey = s.dense[i].key
    let xIndex = s.sparse[xKey.int]
    var j = i - 1
    while j >= 0 and cmp(x, s.dense[j].value) * order < 0:
      let jKey = s.dense[j].key
      s.sparse[s.dense[j + 1].key.int] = s.sparse[jKey.int]
      s.dense[j + 1].key = jKey
      s.dense[j + 1].value = move(s.dense[j].value)
      dec(j)
    s.sparse[s.dense[j + 1].key.int] = xIndex
    s.dense[j + 1].key = xKey
    s.dense[j + 1].value = x

proc clear*[K, V](s: var SparseSet[K, V]) =
  var k: K
  s.sparse.fill(empty(k))
  when not supportsCopyMem(V):
    for i in 0 ..< s.len: s.dense[i].value = default(V)
  s.len = 0

iterator keys*[K, V](s: SparseSet[K, V]): K =
  for i in 0 ..< s.len:
    yield s.dense[i].key

iterator values*[K, V](s: SparseSet[K, V]): V =
  for i in 0 ..< s.len:
    yield s.dense[i].value

iterator pairs*[K, V](s: SparseSet[K, V]): Entry[K, V] =
  for i in 0 ..< s.len:
    yield s.dense[i]

proc len*[K, V](s: SparseSet[K, V]): int = s.len
