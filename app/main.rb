# No dependencies
require 'lib/zif/zif.rb'
require 'lib/zif/sprites/serializable.rb'
require 'lib/zif/services/services.rb'
require 'lib/zif/services/input_service.rb'
require 'lib/zif/services/tick_trace_service.rb'
require 'lib/zif/labels/label.rb'

# Expects $services to be services.rb, works with tick_trace_service.rb
require 'lib/zif/trace/traceable.rb'

# Expects to be included in a Sprite subclass
require 'lib/zif/sprites/assignable.rb'

# Depends on serializable.rb
require 'lib/zif/actions/action.rb'
require 'lib/zif/scenes/scene.rb'

# Depends on serializable.rb, action.rb
require 'lib/zif/actions/sequence.rb'

# Depends on action.rb, sequence.rb
require 'lib/zif/actions/actionable.rb'

# Depends on sequence.rb - expects an Actionable class
require 'lib/zif/actions/animatable.rb'
require 'lib/zif/services/action_service.rb'

# Depends on serializable.rb, assignable.rb, actionable.rb, animatable.rb
require 'lib/zif/sprites/sprite.rb'

# Depends on sprite.rb, zif.rb
require 'lib/zif/sprites/render_target.rb'

# Depends on render_target.rb
require 'lib/zif/sprites/complex_sprite.rb'

# Depends on sprite.rb
require 'lib/zif/services/sprite_registry.rb'
require 'lib/zif/panels/nine_panel_edge.rb'

# Depends on complex_sprite.rb
require 'lib/zif/components/two_stage_button.rb'
require 'lib/zif/panels/nine_panel.rb'

# Depends on scene.rb, render_target.rb
require 'lib/zif/scenes/hud.rb'

# Depends on actionable.rb, zif.rb, - expects $game to be a game.rb
require 'lib/zif/camera.rb'

# Depends on render_target.rb, expects to be initialized with a LayeredTileMap-like @map
require 'lib/zif/layered_tile_map/simple_layer.rb'
require 'lib/zif/layered_tile_map/tiled_layer.rb'

# Depends on simple_layer.rb, tiled_layer.rb, traceable.rb
require 'lib/zif/layered_tile_map/layered_tile_map.rb'

# Depends on traceable.rb, services.rb, input_service.rb, tick_trace_service.rb, action_service.rb, sprite_registry.rb,
#            scene.rb
require 'lib/zif/game.rb'

require 'app/ui/labels/future_label.rb'
require 'app/ui/panels/glass_panel.rb'
require 'app/ui/panels/metal_panel.rb'
require 'app/ui/panels/metal_cutout.rb'
require 'app/ui/components/progress_bar.rb'
require 'app/ui/components/tall_button.rb'

require 'app/scenes/world.rb'
require 'app/scenes/world_loader.rb'
require 'app/scenes/ui_sample.rb'

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
