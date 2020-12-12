import sparseset

type Entity = distinct uint16
proc `==`(a, b: Entity): bool {.borrow.}
proc `$`(x: Entity): string {.borrow.}
template empty*(x: Entity): Entity = Entity(128)

block:
  var x = initSparseSet[Entity, int](128)
  assert x.len == 0
  let ent1 = 1.Entity
  let ent2 = 2.Entity
  x[ent1] = 5
  x[ent2] = 4
  assert(x.len == 2)
  assert x[ent1] == 5
  assert x[ent2] == 4
  x.sort(cmp)
  assert x[ent1] == 5
  assert x[ent2] == 4
  x.del(ent1)
  assert x.len == 1
  x.clear()
  assert x.len == 0
  assert ent2 notin x
  x[ent1] = 10
  assert x.len == 1
  assert x[ent1] == 10
  x.del(ent1)
  assert x.len == 0
  x[ent2] = 9
  assert x[ent2] == 9
