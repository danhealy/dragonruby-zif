# No dependencies
require_relative 'zif.rb'
require_relative 'zif/serializable.rb'
require_relative 'zif/clickable.rb'
require_relative 'zif/key_pressable.rb'
require_relative 'zif/services/service_group.rb'
require_relative 'zif/services/input_service.rb'
require_relative 'zif/services/tick_trace_service.rb'

# Expects $services to be services.rb, works with tick_trace_service.rb
require_relative 'zif/traceable.rb'

# Expects to be included in a Sprite subclass
require_relative 'zif/assignable.rb'

# Depends on serializable.rb
require_relative 'zif/actions/action.rb'
require_relative 'zif/scene.rb'

# Depends on serializable.rb, action.rb
require_relative 'zif/actions/sequence.rb'

# Depends on action.rb, sequence.rb
require_relative 'zif/actions/actionable.rb'

# Depends on actionable.rb
require_relative 'zif/ui/label.rb'
require_relative 'zif/ui/input.rb'

# Depends on sequence.rb - expects an Actionable class
require_relative 'zif/actions/animatable.rb'
require_relative 'zif/services/action_service.rb'

# Depends on serializable.rb, assignable.rb, actionable.rb, animatable.rb
require_relative 'zif/sprite.rb'

# Depends on sprite.rb, zif.rb
require_relative 'zif/render_target.rb'
require_relative 'zif/compound_sprite.rb'

# Depends on sprite.rb
require_relative 'zif/services/sprite_registry.rb'
require_relative 'zif/ui/nine_panel_edge.rb'

# Depends on compound_sprite.rb
require_relative 'zif/ui/two_stage_button.rb'
require_relative 'zif/ui/nine_panel.rb'

# Depends on actionable.rb, zif.rb, - expects $game to be a game.rb
require_relative 'zif/layers/camera.rb'

# Depends on compound_sprite.rb, expects to be initialized with a LayerGroup-like @map
require_relative 'zif/layers/layerable.rb'
require_relative 'zif/layers/tileable.rb'
require_relative 'zif/layers/bitmaskable.rb'
require_relative 'zif/layers/active_layer.rb'
require_relative 'zif/layers/active_tiled_layer.rb'
require_relative 'zif/layers/active_bitmasked_tiled_layer.rb'

# Depends on render_target.rb, expects to be initialized with a LayerGroup-like @map
require_relative 'zif/layers/simple_layer.rb'
require_relative 'zif/layers/tiled_layer.rb'
require_relative 'zif/layers/bitmasked_tiled_layer.rb'

# Depends on simple_layer.rb, tiled_layer.rb, traceable.rb
require_relative 'zif/layers/layer_group.rb'

# Depends on traceable.rb, services.rb, input_service.rb, tick_trace_service.rb, action_service.rb, sprite_registry.rb,
#            scene.rb
require_relative 'zif/game.rb'
