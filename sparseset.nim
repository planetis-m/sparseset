import std / algorithm

type
  Entry*[K, V] = tuple
    key: K
    value: V
  SparseSet*[K: SomeNumber, V] = object
    len: int
    sparse: seq[K]          ## Mapping from sparse handles to dense values.
    dense: seq[Entry[K, V]] ## Mapping from dense values to sparse handles.

proc initSparseSet*[K, V](cap: Natural): SparseSet[K, V] =
  result = SparseSet[K, V](len: 0)
  result.sparse.grow(cap, high(K))
  result.dense.grow(cap, (key: high(K), value: default(V)))

proc contains*[K, V](s: SparseSet[K, V], key: K): bool =
  # Returns true if the sparse is registered to a dense index.
  int(key) < s.sparse.len and s.sparse[key] != high(K)

proc `[]=`*[K, V](s: var SparseSet[K, V], key: K, value: sink V) =
  ## Inserts a `(key, value)` pair into `s`.
  assert int(key) < s.sparse.len, "key must be under len of SparseSet"
  var denseIndex = s.sparse[key]
  if denseIndex == high(K):
    denseIndex = K(s.len)
    s.dense[denseIndex].key = key
    s.sparse[key] = denseIndex
    inc(s.len)
  s.dense[denseIndex].value = value

template get(s, key) =
  if key notin s:
    raise newException(KeyError, "key not in SparseSet")
  result = s.dense[s.sparse[key]].value

proc `[]`*[K, V](s: var SparseSet[K, V], key: K): var V =
  ## Retrieves the value at `s[key]`. The value can be modified.
  ## If `key` is not in `s`, the `KeyError` exception is raised.
  get(s, key)
proc `[]`*[K, V](s: SparseSet[K, V], key: K): lent V =
  ## Retrieves the value at `s[key]`.
  ## If `key` is not in `s`, the `KeyError` exception is raised.
  get(s, key)

proc delete*[K, V](s: var SparseSet[K, V], key: K) =
  ## Deletes `key` from sparse set `s`. Does nothing if the key does not exist.
  let denseIndex = s.sparse[key]
  if denseIndex != high(K):
    let lastIndex = s.len - 1
    let lastKey = s.dense[lastIndex].key
    s.sparse[lastKey] = denseIndex
    s.sparse[key] = high(K)
    s.dense[denseIndex] = move(s.dense[lastIndex])
    s.dense[lastIndex] = (key: high(K), value: default(V))
    s.len.dec

proc sort*[K, V](s: var SparseSet[K, V], cmp: proc (x, y: V): int, order = SortOrder.Ascending) =
  for i in 1 ..< s.len:
    let x = move(s.dense[i].value)
    let xKey = s.dense[i].key
    let xIndex = s.sparse[xKey]
    var j = i - 1
    while j >= 0 and cmp(x, s.dense[j].value) * order < 0:
      let jKey = s.dense[j].key
      s.sparse[s.dense[j + 1].key] = s.sparse[jKey]
      s.dense[j + 1].key = jKey
      s.dense[j + 1].value = move(s.dense[j].value)
      dec(j)
    s.sparse[s.dense[j + 1].key] = xIndex
    s.dense[j + 1].key = xKey
    s.dense[j + 1].value = x

proc clear*[K, V](s: var SparseSet[K, V]) =
  s.sparse.fill(high(K))
  s.dense.fill((key: high(K), value: default(V)))
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

when isMainModule:
  var ss = initSparseSet[uint16, int](128)
  assert ss.len == 0
  let ent1 = 1'u16
  let ent2 = 2'u16
  ss[ent1] = 5
  ss[ent2] = 4
  assert(ss.len == 2)
  assert ss[ent1] == 5
  assert ss[ent2] == 4
  ss.sort(cmp)
  assert ss[ent1] == 5
  assert ss[ent2] == 4
  ss.delete(ent1)
  assert ss.len == 1
  ss.clear()
  assert ss.len == 0
  ss[ent1] = 10
  assert ss.len == 1
  assert ss[ent1] == 10
  ss.delete(ent1)
  assert ss.len == 0
  ss[ent2] = 9
  assert ss[ent2] == 9
