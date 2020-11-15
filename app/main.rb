# No dependencies
require 'app/lib/zif/zif.rb'
require 'app/lib/zif/sprites/serializable.rb'
require 'app/lib/zif/services/services.rb'
require 'app/lib/zif/services/input_service.rb'
require 'app/lib/zif/services/tick_trace_service.rb'

# Expects $services to be services.rb, works with tick_trace_service.rb
require 'app/lib/zif/trace/traceable.rb'

# Expects to be included in a Sprite subclass
require 'app/lib/zif/sprites/assignable.rb'

# Depends on serializable.rb
require 'app/lib/zif/actions/action.rb'
require 'app/lib/zif/scenes/scene.rb'

# Depends on serializable.rb, action.rb
require 'app/lib/zif/actions/sequence.rb'

# Depends on action.rb, sequence.rb
require 'app/lib/zif/actions/actionable.rb'

# Depends on actionable.rb
require 'app/lib/zif/labels/label.rb'

# Depends on sequence.rb - expects an Actionable class
require 'app/lib/zif/actions/animatable.rb'
require 'app/lib/zif/services/action_service.rb'

# Depends on serializable.rb, assignable.rb, actionable.rb, animatable.rb
require 'app/lib/zif/sprites/sprite.rb'

# Depends on sprite.rb, zif.rb
require 'app/lib/zif/sprites/render_target.rb'
require 'app/lib/zif/sprites/compound_sprite.rb'

# Depends on sprite.rb
require 'app/lib/zif/services/sprite_registry.rb'
require 'app/lib/zif/panels/nine_panel_edge.rb'

# Depends on compound_sprite.rb
require 'app/lib/zif/components/two_stage_button.rb'
require 'app/lib/zif/panels/nine_panel.rb'

# Depends on scene.rb, render_target.rb
require 'app/lib/zif/scenes/hud.rb'

# Depends on actionable.rb, zif.rb, - expects $game to be a game.rb
require 'app/lib/zif/camera.rb'

# Depends on compound_sprite.rb, expects to be initialized with a LayeredTileMap-like @map
require 'app/lib/zif/layered_tile_map/layerable.rb'
require 'app/lib/zif/layered_tile_map/active_layer.rb'

# Depends on render_target.rb, expects to be initialized with a LayeredTileMap-like @map
require 'app/lib/zif/layered_tile_map/simple_layer.rb'
require 'app/lib/zif/layered_tile_map/tiled_layer.rb'

# Depends on simple_layer.rb, tiled_layer.rb, traceable.rb
require 'app/lib/zif/layered_tile_map/layered_tile_map.rb'

# Depends on traceable.rb, services.rb, input_service.rb, tick_trace_service.rb, action_service.rb, sprite_registry.rb,
#            scene.rb
require 'app/lib/zif/game.rb'

# Example app specific files:
require 'app/ui/labels/future_label.rb'
require 'app/ui/panels/glass_panel.rb'
require 'app/ui/panels/metal_panel.rb'
require 'app/ui/panels/metal_cutout.rb'
require 'app/ui/components/progress_bar.rb'
require 'app/ui/components/tall_button.rb'

require 'app/scenes/zif_example_scene.rb'
require 'app/scenes/world.rb'
require 'app/scenes/world_loader.rb'
require 'app/scenes/ui_sample.rb'
require 'app/scenes/double_buffer_render_test.rb'
require 'app/scenes/compound_sprite_test.rb'

require 'app/avatar.rb'

# Example usage of a Zif::Game subclass
class ZifExample < Zif::Game
  def initialize
    super()
    1.upto 4 do |i|
      @services[:sprite_registry].register_basic_sprite("dragon_#{i}", 82, 66)
    end
    @services[:sprite_registry].register_basic_sprite(:transparent_gray_32, 32, 32)
    @services[:sprite_registry].register_basic_sprite(:white_1, 64, 64)

    register_scene(:ui_sample, UISample)
    register_scene(:load_world, WorldLoader)
    register_scene(:load_double_buffer_render_test, DoubleBufferRenderTest)
    register_scene(:load_compound_sprite_test, CompoundSpriteTest)
    @scene = UISample.new
  end
end

def tick(args)
  if args.tick_count == 2
    $game = ZifExample.new
    $game.scene.prepare_scene # Need this here because it references $game
  end

  $game&.perform_tick
end
