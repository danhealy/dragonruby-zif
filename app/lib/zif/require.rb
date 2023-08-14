# No dependencies
require_relative 'zif.rb'
require_relative 'serializable.rb'
require_relative 'clickable.rb'
require_relative 'key_pressable.rb'
require_relative 'services/service_group.rb'
require_relative 'services/input_service.rb'
require_relative 'services/tick_trace_service.rb'

# Expects $services to be services.rb, works with tick_trace_service.rb
require_relative 'traceable.rb'

# Expects to be included in a Sprite subclass
require_relative 'assignable.rb'

# Depends on serializable.rb
require_relative 'actions/action.rb'
require_relative 'scene.rb'

# Depends on serializable.rb, action.rb
require_relative 'actions/sequence.rb'

# Depends on action.rb, sequence.rb
require_relative 'actions/actionable.rb'

# Depends on actionable.rb
require_relative 'ui/label.rb'
require_relative 'ui/input.rb'

# Depends on sequence.rb - expects an Actionable class
require_relative 'actions/animatable.rb'
require_relative 'services/action_service.rb'

# Depends on serializable.rb, assignable.rb, actionable.rb, animatable.rb
require_relative 'sprite.rb'

# Depends on sprite.rb, zif.rb
require_relative 'render_target.rb'
require_relative 'compound_sprite.rb'

# Depends on sprite.rb
require_relative 'services/sprite_registry.rb'
require_relative 'ui/nine_panel_edge.rb'

# Depends on compound_sprite.rb
require_relative 'ui/two_stage_button.rb'
require_relative 'ui/nine_panel.rb'

# Depends on actionable.rb, zif.rb, - expects $game to be a game.rb
require_relative 'layers/camera.rb'

# Depends on compound_sprite.rb, expects to be initialized with a LayerGroup-like @map
require_relative 'layers/layerable.rb'
require_relative 'layers/tileable.rb'
require_relative 'layers/bitmaskable.rb'
require_relative 'layers/active_layer.rb'
require_relative 'layers/active_tiled_layer.rb'
require_relative 'layers/active_bitmasked_tiled_layer.rb'

# Depends on render_target.rb, expects to be initialized with a LayerGroup-like @map
require_relative 'layers/simple_layer.rb'
require_relative 'layers/tiled_layer.rb'
require_relative 'layers/bitmasked_tiled_layer.rb'

# Depends on simple_layer.rb, tiled_layer.rb, traceable.rb
require_relative 'layers/layer_group.rb'

# Depends on traceable.rb, services.rb, input_service.rb, tick_trace_service.rb, action_service.rb, sprite_registry.rb,
#            scene.rb
require_relative 'game.rb'
