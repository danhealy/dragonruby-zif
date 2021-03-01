# No dependencies
require 'app/lib/zif/zif.rb'
require 'app/lib/zif/serializable.rb'
require 'app/lib/zif/clickable.rb'
require 'app/lib/zif/services/service_group.rb'
require 'app/lib/zif/services/input_service.rb'
require 'app/lib/zif/services/tick_trace_service.rb'

# Expects $services to be services.rb, works with tick_trace_service.rb
require 'app/lib/zif/traceable.rb'

# Expects to be included in a Sprite subclass
require 'app/lib/zif/assignable.rb'

# Depends on serializable.rb
require 'app/lib/zif/actions/action.rb'
require 'app/lib/zif/scene.rb'

# Depends on serializable.rb, action.rb
require 'app/lib/zif/actions/sequence.rb'

# Depends on action.rb, sequence.rb
require 'app/lib/zif/actions/actionable.rb'

# Depends on actionable.rb
require 'app/lib/zif/ui/label.rb'

# Depends on sequence.rb - expects an Actionable class
require 'app/lib/zif/actions/animatable.rb'
require 'app/lib/zif/services/action_service.rb'

# Depends on serializable.rb, assignable.rb, actionable.rb, animatable.rb
require 'app/lib/zif/sprite.rb'

# Depends on sprite.rb, zif.rb
require 'app/lib/zif/render_target.rb'
require 'app/lib/zif/compound_sprite.rb'

# Depends on sprite.rb
require 'app/lib/zif/services/sprite_registry.rb'
require 'app/lib/zif/ui/nine_panel_edge.rb'

# Depends on compound_sprite.rb
require 'app/lib/zif/ui/two_stage_button.rb'
require 'app/lib/zif/ui/nine_panel.rb'

# Depends on actionable.rb, zif.rb, - expects $game to be a game.rb
require 'app/lib/zif/layers/camera.rb'

# Depends on compound_sprite.rb, expects to be initialized with a LayerGroup-like @map
require 'app/lib/zif/layers/layerable.rb'
require 'app/lib/zif/layers/tileable.rb'
require 'app/lib/zif/layers/bitmaskable.rb'
require 'app/lib/zif/layers/active_layer.rb'
require 'app/lib/zif/layers/active_tiled_layer.rb'
require 'app/lib/zif/layers/active_bitmasked_tiled_layer.rb'

# Depends on render_target.rb, expects to be initialized with a LayerGroup-like @map
require 'app/lib/zif/layers/simple_layer.rb'
require 'app/lib/zif/layers/tiled_layer.rb'
require 'app/lib/zif/layers/bitmasked_tiled_layer.rb'

# Depends on simple_layer.rb, tiled_layer.rb, traceable.rb
require 'app/lib/zif/layers/layer_group.rb'

# Depends on traceable.rb, services.rb, input_service.rb, tick_trace_service.rb, action_service.rb, sprite_registry.rb,
#            scene.rb
require 'app/lib/zif/game.rb'
