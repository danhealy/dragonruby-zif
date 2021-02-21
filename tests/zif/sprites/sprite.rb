require 'tests/test_helpers.rb'

def test_clicked_outside_of_rect_returns_nil(_args, assert)
  sprite = TestHelpers.sprite_at(20, 20, 100, 100)

  assert.nil! sprite.clicked?([200, 200], :down)
end

def test_clicked_inside_of_rect_returns_sprite(_args, assert)
  sprite = TestHelpers.sprite_at(20, 20, 100, 100)

  assert.equal! sprite, sprite.clicked?([50, 50], :down)
  assert.equal! sprite, sprite.clicked?([10, 10], :up)
  assert.equal! sprite, sprite.clicked?([80, 100], :changed)
end

def test_clicked_mouse_up_handler(_args, assert)
  called_args = []

  sprite = TestHelpers.sprite_at(20, 20, 100, 100)
  sprite.on_mouse_down = ->(sprite, point) { called_args = [sprite, point] }
  sprite.clicked?([50, 50], :down)

  assert.equal! called_args, [sprite, [50, 50]]
end

def test_clicked_mouse_changed_handler(_args, assert)
  called_args = []

  sprite = TestHelpers.sprite_at(20, 20, 100, 100)
  sprite.on_mouse_changed = ->(sprite, point) { called_args = [sprite, point] }
  sprite.clicked?([50, 50], :changed)

  assert.equal! called_args, [sprite, [50, 50]]
end

def test_clicked_mouse_down_handler(_args, assert)
  called_args = []

  sprite = TestHelpers.sprite_at(20, 20, 100, 100)
  sprite.on_mouse_up = ->(sprite, point) { called_args = [sprite, point] }
  sprite.clicked?([50, 50], :up)

  assert.equal! called_args, [sprite, [50, 50]]
end

$gtk.reset 100
$gtk.log_level = :off
