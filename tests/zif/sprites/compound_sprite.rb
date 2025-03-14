require 'tests/test_helpers.rb'

def default_transform
  return { offset: {x: 0, y: 0 }, zoom: {x: 1.0, y: 1.0 } }
end

def expect_transforms_eq(assert, t1, t2)
  assert.equal! t1.offset.x, t2.offset.x
  assert.equal! t1.offset.y, t2.offset.y
  assert.equal! t1.zoom.x, t2.zoom.x
  assert.equal! t1.zoom.y, t2.zoom.y
end

def test_csprite_transform_default(_args, assert)
  parent = TestHelpers.csprite_at(20, 20, 100, 100)

  expect_transforms_eq(assert, parent.transform, default_transform)
end
