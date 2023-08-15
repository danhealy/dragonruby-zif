# Require all of the Zif library:
require 'lib/require.rb'

# Required files for the Zif Example App:
require 'app/require.rb'

# This is the tick method required for the ExampleApp in the top level namespace, from +app/main.rb+
def tick(args)
  if args.tick_count == 2
    $game = ExampleApp::ZifExample.new
    $game.scene.prepare_scene # Need this here because it references $game
  end

  $game&.perform_tick
end
