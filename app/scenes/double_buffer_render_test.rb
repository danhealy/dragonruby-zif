# Demonstration of the performance improvement by using the double buffering technique for RenderTargets
class DoubleBufferRenderTest < ZifExampleScene
  attr_accessor :map

  def initialize
    super
    @next_scene = :load_compound_sprite_test
    # Turn the threshold down to see a breakdown of performance:
    # tracer.time_threshold = 0.002

    mark('#initialize: Begin')

    @map = Zif::LayeredTileMap.new('double_buffered_test', 64, 64, 20, 12)
    @map.new_simple_layer(:fully_rerender)
    @map.new_simple_layer(:double_buffered_rerender)

    @map.layers[:fully_rerender].source_sprites = initialize_sprites(:fully_rerender)
    @map.layers[:double_buffered_rerender].source_sprites = initialize_sprites(:double_buffered_rerender, 1)

    @rendering = true
    @full_render = false
    @never_rendered = true
    mark('#initialize: Finished')
  end

  def initialize_sprites(name, page=0)
    992.times.map do |i|
      y_i, x_i = i.divmod(32)
      $game.services[:sprite_registry].construct(:white_1).tap do |s|
        s.name = "#{name}_#{x_i}_#{y_i}"
        s.b = page.zero? ? 200 : 0
        s.r = 100 + x_i
        s.g = 100 + y_i
        s.x = (x_i * (16 + 1)) + (page * 640) + 50
        s.y = (y_i * (16 + 1)) + 70
        s.w = 16
        s.h = 16
        s.on_mouse_up = lambda do |_sprite, _point|
          flags_from_clicks(name)
        end
      end
    end
  end

  def prepare_scene
    super

    $game.services[:input_service].register_clickable(@map.layers[:fully_rerender].containing_sprite)
    $game.services[:input_service].register_clickable(@map.layers[:double_buffered_rerender].containing_sprite)

    cs = @map.layer_containing_sprites
    $gtk.args.outputs.static_sprites << cs
  end

  def flags_from_clicks(layer)
    if (@full_render && (layer == :fully_rerender)) || (!@full_render && (layer == :double_buffered_rerender))
      @rendering = !@rendering
    end

    if (@full_render && (layer == :double_buffered_rerender)) || (!@full_render && (layer == :fully_rerender))
      @full_render = !@full_render
      @rendering   = true
    end

    puts "Clicked #{layer}.  Rendering #{@rendering}, active layer #{@full_render}"
  end

  def perform_tick
    mark('#perform_tick: Begin')

    $gtk.args.outputs.background_color = [0, 0, 0, 0]
    mark('#perform_tick: Init')

    @full_render = !@full_render if $gtk.args.inputs.keyboard.key_up.x
    @rendering   = !@rendering if $gtk.args.inputs.keyboard.key_up.z

    rerender_focus
    mark('#perform_tick: rerender_focus')

    perform_tick_debug_labels

    mark('#perform_tick: Finished')
    super
  end

  def rerender_focus
    if @rendering
      cur_layer = @full_render ? :fully_rerender : :double_buffered_rerender
      s = @map.layers[cur_layer].source_sprites.sample
      s.r, s.g, s.b = Zif.hsv_to_rgb($gtk.args.tick_count % 360, 100, 100)

      # This is the magic.
      @map.layers[cur_layer].rerender_rect = s.rect if (cur_layer == :double_buffered_rerender) && !@never_rendered
    end

    @map.layers[:fully_rerender].should_render           = @never_rendered || (@rendering && @full_render)
    @map.layers[:double_buffered_rerender].should_render = @never_rendered || (@rendering && !@full_render)

    mark('#rerender_focus: Setup')
    @map.refresh
    mark('#rerender_focus: Refresh')
    @never_rendered = false
  end

  # rubocop:disable Layout/LineLength
  # rubocop:disable Style/NestedTernaryOperator
  def perform_tick_debug_labels
    color = {r: 255, g: 255, b: 255, a: 255}
    active_color = {r: 255, g: 0, b: 0, a: 255}
    $gtk.args.outputs.labels << { x: 8, y: 720 - 48, text: "Render mode (press X to change, Z for off): #{@rendering ? (@full_render ? 'Full re-render' : 'Double buffer re-render') : 'Off'}" }.merge(color)
    $gtk.args.outputs.labels << { x: 50,  y: 720 - 100, text: 'Full re-render' }.merge(@rendering && @full_render ? active_color : color)
    $gtk.args.outputs.labels << { x: 690, y: 720 - 100, text: 'Double buffered re-render' }.merge(@rendering && !@full_render ? active_color : color)
  end
  # rubocop:enable Layout/LineLength
  # rubocop:enable Style/NestedTernaryOperator
end
