require 'tests/test_helpers.rb'

def test_unloads_scene(_args, assert)
  test_scene_class = Class.new(Zif::Scene) do
    attr_reader :unloaded

    def perform_tick
      Class.new(Zif::Scene)
    end

    def unload_scene
      @unloaded = true
    end
  end

  test_scene = test_scene_class.new
  game = Zif::Game.new.tap { |g| g.scene = test_scene }
  game.perform_tick

  assert.true! test_scene.unloaded
end
