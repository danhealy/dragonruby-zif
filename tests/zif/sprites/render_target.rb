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

$gtk.reset 100
$gtk.log_level = :off
