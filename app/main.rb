# Require all of the Zif library:
require 'app/lib/zif/require.rb'

# Required files for the Zif Example App:
require 'app/require.rb'

def tick(args)
  if args.tick_count == 2
    $game = ZifExample.new
    $game.scene.prepare_scene # Need this here because it references $game
  end

  $game&.perform_tick
end
