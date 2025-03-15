require 'tests/test_helpers.rb'

def expect_transforms_eq(assert, t1, t2)
  assert.equal! t1[0], t2[0]
  assert.equal! t1[1], t2[1]
  assert.equal! t1[2], t2[2]
  assert.equal! t1[3], t2[3]
end


def test_csprite_orig_transform_default(_args, assert)
  cs = TestHelpers.csprite_at(0, 0, 100, 100)

  expect_transforms_eq(assert, cs.transform, [0, 0, 1.0, 1.0])
end

def test_csprite_orig_transform_scaled_up(_args, assert)
  cs = TestHelpers.csprite_at(0, 0, 100, 100).tap do |cs|
    cs.source_w = 50
    cs.source_h = 50
  end

  expect_transforms_eq(assert, cs.transform, [0, 0, 2.0, 2.0])
end

def test_csprite_orig_transform_scaled_down(_args, assert)
  cs = TestHelpers.csprite_at(0, 0, 100, 100).tap do |cs|
    cs.source_w = 200
    cs.source_h = 200
  end

  expect_transforms_eq(assert, cs.transform, [0, 0, 0.5, 0.5])
end


def test_csprite_transform_default(_args, assert)
  cs = TestHelpers.csprite_at(20, 20, 100, 100)

  expect_transforms_eq(assert, cs.transform, [20, 20, 1.0, 1.0])
end

def test_csprite_transform_scaled_up(_args, assert)
  cs = TestHelpers.csprite_at(20, 20, 100, 100).tap do |cs|
    cs.source_w = 50
    cs.source_h = 50
  end

  expect_transforms_eq(assert, cs.transform, [40, 40, 2.0, 2.0])
end

def test_csprite_transform_scaled_down(_args, assert)
  cs = TestHelpers.csprite_at(20, 20, 100, 100).tap do |cs|
    cs.source_w = 200
    cs.source_h = 200
  end

  expect_transforms_eq(assert, cs.transform, [10, 10, 0.5, 0.5])
end


def test_csprite_orig_transform_panned(_args, assert)
  cs = TestHelpers.csprite_at(0, 0, 100, 100).tap do |cs|
    cs.source_x = 50
    cs.source_y = 50
  end

  expect_transforms_eq(assert, cs.transform, [-50, -50, 1.0, 1.0])
end

def test_csprite_orig_transform_panned_and_scaled_down(_args, assert)
  cs = TestHelpers.csprite_at(0, 0, 100, 100).tap do |cs|
    cs.source_x = 50
    cs.source_y = 50
    cs.source_w = 200
    cs.source_h = 200
  end

  expect_transforms_eq(assert, cs.transform, [-25, -25, 0.5, 0.5])
end

def test_csprite_orig_transform_panned_and_scaled_up(_args, assert)
  cs = TestHelpers.csprite_at(0, 0, 100, 100).tap do |cs|
    cs.source_x = 50
    cs.source_y = 50
    cs.source_w = 50
    cs.source_h = 50
  end

  expect_transforms_eq(assert, cs.transform, [-100, -100, 2.0, 2.0])
end


def test_csprite_transform_panned(_args, assert)
  cs = TestHelpers.csprite_at(20, 20, 100, 100).tap do |cs|
    cs.source_x = 50
    cs.source_y = 50
  end

  expect_transforms_eq(assert, cs.transform, [-30, -30, 1.0, 1.0])
end

def test_csprite_transform_panned_and_scaled_down(_args, assert)
  cs = TestHelpers.csprite_at(20, 20, 100, 100).tap do |cs|
    cs.source_x = 50
    cs.source_y = 50
    cs.source_w = 200
    cs.source_h = 200
  end

  expect_transforms_eq(assert, cs.transform, [-15, -15, 0.5, 0.5])
end

def test_csprite_transform_panned_and_scaled_up(_args, assert)
  cs = TestHelpers.csprite_at(20, 20, 100, 100).tap do |cs|
    cs.source_x = 50
    cs.source_y = 50
    cs.source_w = 50
    cs.source_h = 50
  end

  expect_transforms_eq(assert, cs.transform, [-60, -60, 2.0, 2.0])
end


def test_csprite_orig_transform_parent_default(_args, assert)
  cs = TestHelpers.csprite_at(0, 0, 100, 100)
  p = [0, 0, 1.0, 1.0]

  expect_transforms_eq(assert, cs.transform(*p), p)
end

def test_csprite_orig_transform_parent_scaled_up(_args, assert)
  cs = TestHelpers.csprite_at(0, 0, 100, 100)
  p = [0, 0, 0.5, 0.5]

  expect_transforms_eq(assert, cs.transform(*p), p)
end

def test_csprite_orig_transform_parent_scaled_down(_args, assert)
  cs = TestHelpers.csprite_at(0, 0, 100, 100)
  p = [0, 0, 0.5, 0.5]

  expect_transforms_eq(assert, cs.transform(*p), p)
end


def test_csprite_transform_parent_default(_args, assert)
  cs = TestHelpers.csprite_at(20, 20, 100, 100)
  p = [0, 0, 1.0, 1.0]
  c = [20, 20, 1.0, 1.0]

  expect_transforms_eq(assert, cs.transform(*p), c)
end

def test_csprite_transform_parent_scaled_up(_args, assert)
  cs = TestHelpers.csprite_at(20, 20, 100, 100)
  p = [0, 0, 2.0, 2.0]
  c = [40, 40, 2.0, 2.0]

  expect_transforms_eq(assert, cs.transform(*p), c)
end

def test_csprite_transform_parent_scaled_down(_args, assert)
  cs = TestHelpers.csprite_at(20, 20, 100, 100)
  p = [0, 0, 0.5, 0.5]
  c = [10, 10, 0.5, 0.5]

  expect_transforms_eq(assert, cs.transform(*p), c)
end


def test_csprite_transform_child_scaled_up(_args, assert)
  cs = TestHelpers.csprite_at(20, 20, 100, 100).tap do |cs|
    cs.source_w = 50
    cs.source_h = 50
  end
  p = [0, 0, 1.0, 1.0]
  c = [40, 40, 2.0, 2.0]

  expect_transforms_eq(assert, cs.transform(*p), c)
end

def test_csprite_transform_child_scaled_down(_args, assert)
  cs = TestHelpers.csprite_at(20, 20, 100, 100).tap do |cs|
    cs.source_w = 200
    cs.source_h = 200
  end
  p = [0, 0, 1.0, 1.0]
  c = [10, 10, 0.5, 0.5]

  expect_transforms_eq(assert, cs.transform(*p), c)
end


def test_csprite_transform_child_and_parent_scaled_up(_args, assert)
  cs = TestHelpers.csprite_at(20, 20, 100, 100).tap do |cs|
    cs.source_w = 50
    cs.source_h = 50
  end
  p = [0, 0, 2.0, 2.0]
  c = [80, 80, 4.0, 4.0]

  expect_transforms_eq(assert, cs.transform(*p), c)
end

def test_csprite_transform_child_and_parent_scaled_down(_args, assert)
  cs = TestHelpers.csprite_at(20, 20, 100, 100).tap do |cs|
    cs.source_w = 200
    cs.source_h = 200
  end
  p = [0, 0, 0.5, 0.5]
  c = [5, 5, 0.25, 0.25]

  expect_transforms_eq(assert, cs.transform(*p), c)
end


def test_csprite_transform_child_scaled_up_and_parent_scaled_down(_args, assert)
  cs = TestHelpers.csprite_at(20, 20, 100, 100).tap do |cs|
    cs.source_w = 50
    cs.source_h = 50
  end
  p = [0, 0, 0.5, 0.5]
  c = [20, 20, 1.0, 1.0]

  expect_transforms_eq(assert, cs.transform(*p), c)
end

def test_csprite_transform_child_scaled_down_and_parent_scaled_up(_args, assert)
  cs = TestHelpers.csprite_at(20, 20, 100, 100).tap do |cs|
    cs.source_w = 200
    cs.source_h = 200
  end
  p = [0, 0, 2.0, 2.0]
  c = [20, 20, 1.0, 1.0]

  expect_transforms_eq(assert, cs.transform(*p), c)
end


def test_csprite_transform_child_panned_and_scaled_up(_args, assert)
  cs = TestHelpers.csprite_at(20, 20, 100, 100).tap do |cs|
    cs.source_x = 50
    cs.source_y = 50
    cs.source_w = 50
    cs.source_h = 50
  end
  p = [0, 0, 1.0, 1.0]
  c = [-60, -60, 2.0, 2.0]

  expect_transforms_eq(assert, cs.transform(*p), c)
end

def test_csprite_transform_child_panned_scaled_down(_args, assert)
  cs = TestHelpers.csprite_at(20, 20, 100, 100).tap do |cs|
    cs.source_x = 50
    cs.source_y = 50
    cs.source_w = 200
    cs.source_h = 200
  end
  p = [0, 0, 1.0, 1.0]
  c = [-15, -15, 0.5, 0.5]

  expect_transforms_eq(assert, cs.transform(*p), c)
end


def test_csprite_transform_child_and_parent_panned_and_scaled_up(_args, assert)
  cs = TestHelpers.csprite_at(20, 20, 100, 100).tap do |cs|
    cs.source_x = 50
    cs.source_y = 50
    cs.source_w = 50
    cs.source_h = 50
  end
  p = [20, 20, 2.0, 2.0]
  c = [-100, -100, 4.0, 4.0]

  expect_transforms_eq(assert, cs.transform(*p), c)
end

def test_csprite_transform_child_and_parent_panned_scaled_down(_args, assert)
  cs = TestHelpers.csprite_at(20, 20, 100, 100).tap do |cs|
    cs.source_x = 50
    cs.source_y = 50
    cs.source_w = 200
    cs.source_h = 200
  end
  p = [20, 20, 0.5, 0.5]
  c = [12.5, 12.5, 0.25, 0.25]

  expect_transforms_eq(assert, cs.transform(*p), c)
end
