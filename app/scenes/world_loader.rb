# This is a loading screen that comes up before switching to World
# It's required because the World will take a little while to generate all of the floor sprites
# It's also a demonstration of automatic scene switching
class WorldLoader < Zif::Scene
  include Zif::Traceable

  attr_accessor :world, :ready

  def initialize
    @tracer_service_name = :tracer
    @world = World.new
    @ready = false
    @floor_progress = ProgressBar.new(:world_loader_progress, 640, @world.initialization_percent(:tiles), :green)
    @floor_label = FutureLabel.new('Generating Floor...', 0, 1).tap do |l|
      l.x = 640
      l.y = 400
      l.r = 255
      l.g = 255
      l.b = 255
      l.a = 255
    end

    @stuff_progress = ProgressBar.new(
      :world_loader_stuff_progress,
      640,
      @world.initialization_percent(:stuff),
      :red
    )
    @stuff_label = FutureLabel.new('Generating Stuff...', 0, 1).tap do |l|
      l.x = 640
      l.y = 300
      l.r = 255
      l.g = 255
      l.b = 255
      l.a = 255
    end
  end

  def prepare_scene
    $game.services[:action_service].reset_actionables
    $game.services[:input_service].reset
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

    # rubocop:disable Layout/LineLength
    color = {r: 255, g: 255, b: 255, a: 255}
    $gtk.args.outputs.labels << { x: 8, y: 720 - 8, text: "#{self.class.name}." }.merge(color)
    $gtk.args.outputs.labels << { x: 8, y: 720 - 28, text: "#{tracer&.last_tick_ms} #{$gtk.args.gtk.current_framerate}fps" }.merge(color)
    $gtk.args.outputs.labels << { x: 8, y: 60, text: "Last slowest mark: #{tracer&.slowest_mark}" }.merge(color)
    # rubocop:enable Layout/LineLength

    # Returning the other Scene instance so the Game knows to switch scenes.  Demonstrating an automatic scene switch
    return @world if @ready
  end
end
