require 'tests/test_helpers.rb'

def test_project_to(_args, assert)
  render_target = Zif::RenderTarget.new(:target)

  render_target.project_to(x: 20, y: 20, w: 200, h: 200)

  assert.equal! render_target.containing_sprite.rect, [20, 20, 200, 200]
end

def test_project_from(_args, assert)
  render_target = Zif::RenderTarget.new(:target)

  render_target.project_from(x: 20, y: 20, w: 200, h: 200)

  assert.equal! render_target.containing_sprite.source_rect, [20, 20, 200, 200]
end

def test_clicked_forwards_to_contained_sprite(_args, assert)
  called_args = []

  sprite = TestHelpers.sprite_at(20, 20, 100, 100)
  sprite.on_mouse_down = ->(sprite, point) { called_args = [sprite, point] }

  render_target = Zif::RenderTarget.new(:target)
  render_target.sprites << sprite
  render_target.project_to(x: 200, y: 200, w: 500, h: 500) # Sprite at Screen rect: [220, 220, 100, 100]
  render_target.containing_sprite.clicked?([250, 250], :down)

  assert.equal! called_args, [sprite, [50, 50]]
end
