test "hello test", ->
  ok( 1 == 1, "Passed!" )

test "URN construction", ->
  equal( cite_urn('namespace','collection','row'), 'urn:cite:namespace:collection.row' )
  equal( cite_urn('namespace','collection','row','version'), 'urn:cite:namespace:collection.row.version' )
