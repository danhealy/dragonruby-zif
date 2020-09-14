# This is a loading screen that comes up before switching to World
# It's required because the World will take a little while to generate all of the floor sprites
# It's also a demonstration of automatic scene switching
class WorldLoader < Zif::Scene
  attr_accessor :world, :ready

  def initialize
    @world = World.new
    @ready = false
    @floor_progress = ProgressBar.new(:world_loader_progress, 640, @world.initialization_percent(:tiles), :green)
    @floor_label = FutureLabel.new('Generating Floor...', 0, 1).label_attrs.merge({
      x: 640,
      y: 400,
      r: 255,
      g: 255,
      b: 255,
      a: 255
    })

    @stuff_progress = ProgressBar.new(
      :world_loader_stuff_progress,
      640,
      @world.initialization_percent(:stuff),
      :red
    )
    @stuff_label = FutureLabel.new('Generating Stuff...', 0, 1).label_attrs.merge({
      x: 640,
      y: 300,
      r: 255,
      g: 255,
      b: 255,
      a: 255
    })
  end

  def prepare_scene
    $game.services[:action_service].reset_actionables
    $game.services[:input_service].reset_clickables
  end

  def perform_tick
    $gtk.args.outputs.background_color = [0, 0, 0, 0]

    @ready = @world.ready # Need to offset this by 1 tick to fix the progress bar at the end
    @world.initialize_tiles

    sprites = [@floor_progress.containing_sprite(320, 340)]
    labels = [@floor_label]

    @floor_progress.progress = @world.initialization_percent(:tiles)

    if @world.initialization_percent(:tiles) >= 0.99
      labels << @stuff_label
      @stuff_progress.progress = @world.initialization_percent(:stuff)

      sprites << @stuff_progress.containing_sprite(320, 240)
    end
    $gtk.args.outputs.sprites << sprites
    $gtk.args.outputs.labels << labels

    # Returning the other Scene instance so the Game knows to switch scenes.  Demonstrating an automatic scene switch
    return @world if @ready
  end
end
