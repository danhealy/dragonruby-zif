require 'tests/test_helpers.rb'

module GameTest
  class SceneA < Zif::Scene
    attr_reader :unloaded

    def perform_tick
      SceneB
    end

    def unload_scene
      @unloaded = true
    end
  end
  SceneB = Class.new(Zif::Scene)
end

def test_unloads_scene(_args, assert)
  scene_a = GameTest::SceneA.new
  game = Zif::Game.new.tap { |g| g.scene = scene_a }
  game.perform_tick

  assert.true! scene_a.unloaded
end

$gtk.reset 100
$gtk.log_level = :off
