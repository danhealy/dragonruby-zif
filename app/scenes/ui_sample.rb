# An example of all the UI elements
# Also demonstrates usage of services:
# - Input service (handles the two button Clickables)
# - Action service (handles actions "tweening"/"easing" of the Dragon sprite)
# - Sprite registry (provides a prototype to construct the Dragon sprite by name)
# - TickTrace service (will get triggered when the "Simulate Lag" button is clicked, reports slow sections of code)
class UISample < Zif::Scene
  include Zif::Traceable
  attr_accessor :cur_color, :button, :counter, :count_progress, :random_lengths, :all_sprites, :all_labels

  DEBUG_LABEL_COLOR = { r: 255, g: 255, b: 255 }.freeze

  def initialize
    super()

    $gtk.args.outputs.background_color = [0, 0, 0]
    @counter = 0
    @random_lengths = Array.new(10) { rand(160) + 40 } # Just some shared random numbers
    change_color

    # TwoStageButton (which TallButton inherits from) accepts a block in the constructor
    # The block is executed when the button is registered as a clickable, and it receives the mouse up event
    # You can give sprites callback functions for on_mouse_down, .._changed (mouse is moving while down), and .._up
    @button = TallButton.new(:static_button, 300, :blue, 'Press Me', 2) do |_point|
      puts 'UISample: Button pressed!'
      # You should check the state of the button as it's possible to click down on the button, but then move the mouse
      # away and let go of the mouse away from the button
      # The state is updated automatically as TwoStageButton creates an on_mouse_changed callback for you.
      if @button.is_pressed
        @counter += 1

        @count_progress = ProgressBar.new(:count_progress, 400, 0, @cur_color) if @counter == 1
        @count_progress.progress = @counter / 10.0

        @load_next_scene_next_tick = true if @counter >= 10
      end
    end
  end

  # #prepare_scene and #unload_scene are called by Game before the scene gets run for the first time, and after it
  # detects a scene change has been requested, respectively
  def prepare_scene
    # These can't be in initialize due to $game not being set during init
    @delay_button = TallButton.new(:delay_button, 300, :red, 'Simulate Lag', 2) do |_point|
      puts 'UISample: Delay button pressed!'
      $game.services[:tracer].mark('UISample: Button was clicked - demonstrating Tick Trace service')
      sleep(0.5)
      $game.services[:tracer].mark('UISample: Woke up from 500ms second nap')
    end

    # Create a sprite from a prototype registered in the Sprite Registry service
    # This returns a Zif::Sprite with the proper w/h/path settings
    @dragon = $game.services[:sprite_registry].construct('dragon_1').tap do |s|
      s.x = 600
      s.y = 100
    end

    # Run some action sequences on this sprite
    @dragon.run(@dragon.fade_out_and_in_forever)
    @dragon.run(
      Zif::Sequence.new(
        [
          # Move from starting position to 1000x over 1 second, starting slowly, then flip the sprite at the end
          @dragon.new_action({x: 1000}, 1.seconds, :smooth_start) { @dragon.flip_horizontally = true },
          # Move from the new position (1000x) back to the start 600x over 2 seconds, stopping slowly, then flip again
          @dragon.new_action({x: 600}, 2.seconds, :smooth_stop) { @dragon.flip_horizontally = false }
        ],
        :forever
      )
    )

    @dragon.new_basic_animation(
      :fly,
      1.upto(4).map { |i| ["dragon_#{i}", 4] } + 3.downto(2).map { |i| ["dragon_#{i}", 4] }
    )

    @dragon.run_animation_sequence(:fly)

    # You have to explicity tell the action and input services which sprites to handle
    # Clickables must be registered with the input service to be tested when a click is detected
    # Actionables must be registered with the action service to be notified to update based on the running Actions
    $game.services[:action_service].register_actionable(@dragon)
    $game.services[:input_service].register_clickable(@button)
    $game.services[:input_service].register_clickable(@delay_button)
  end

  def unload_scene
    # You probably want to remove the things registered with the services when scenes change
    # You can remove items explicitly using #remove_.., but #reset_.. will clear everything
    $game.services[:action_service].reset_actionables
    $game.services[:input_service].reset_clickables
  end

  def change_color
    @cur_color = %i[blue green red white yellow].sample
  end

  def color_should_change?
    ($gtk.args.tick_count % @random_lengths[0]).zero?
  end

  def perform_tick
    $gtk.args.outputs.background_color = [0, 0, 0]
    @all_sprites = []
    @all_labels = []

    change_color if color_should_change?

    display_metal_panel
    display_glass_panel
    display_progress_bar
    display_button
    display_interactable_button
    display_lag_button
    display_action_example

    # You generally want to append to args.outputs.___ only once per tick
    $gtk.args.outputs.sprites << @all_sprites

    @all_labels << {
      x:    8,
      y:    720 - 8,
      text: "#{$gtk.args.gtk.current_framerate}fps",
      r:    255,
      g:    255,
      b:    255,
      a:    255
    }

    $gtk.args.outputs.labels << @all_labels

    return :load_world if @load_next_scene

    # Delay loading next scene so you can see the button come up on the 20th click
    @load_next_scene = @load_next_scene_next_tick
  end

  def display_metal_panel
    cur_w = MetalPanel.min_width + 200 + (200 * Zif.ease($gtk.args.tick_count, @random_lengths[1])).floor
    cur_h = MetalPanel.min_height + 200 + (200 * Zif.ease($gtk.args.tick_count, @random_lengths[2])).floor

    @metal = MetalPanel.new(:metal_panel, cur_w, cur_h, 'Hello World', @cur_color)
    # @metal.change_color(@cur_color) if color_should_change?
    # @metal.rescale(cur_w, cur_h)
    # TODO: Get rescaling working properly. For now just recreate.

    @all_sprites << @metal.containing_sprite(60, 60)
    @all_labels << {
      x:    60,
      y:    600,
      text: "Scaling custom 9-slice: #{cur_w}x#{cur_h}"
    }.merge(DEBUG_LABEL_COLOR)

    return unless (cur_w > 75) && (cur_h > 100)

    # Draw the cutout
    cutout = MetalCutout.new(:metal_cutout, cur_w - 50, cur_h - 100)
    @all_sprites << cutout.containing_sprite(60 + 25, 60 + 25)
  end

  def display_glass_panel
    cuts = ('%04b' % (($gtk.args.tick_count / 60) % 16)).chars.map { |bit| bit == '1' }
    glass = GlassPanel.new(:glass_panel, 600, 600, cuts)

    @all_labels << { x: 600, y: 700, text: "Glass panel cuts: #{cuts}" }.merge(DEBUG_LABEL_COLOR)
    @all_sprites << glass.containing_sprite(550, 60)
  end

  def display_progress_bar
    cur_progress       = (0.5 + 0.5 * Zif.ease($gtk.args.tick_count, @random_lengths[3])).round(4)
    cur_progress_width = 150 + (50 * Zif.ease($gtk.args.tick_count, @random_lengths[4])).floor

    prog = ProgressBar.new(:progress, cur_progress_width, cur_progress, @cur_color)
    @all_sprites << prog.containing_sprite(600, 580)
    @all_labels << {
      x:    600,
      y:    640,
      text: "Progress bar: width #{cur_progress_width}, progress #{(cur_progress * 100).round}%"
    }.merge(DEBUG_LABEL_COLOR)
  end

  def display_button
    cur_button_length = 20 + 200 + (200 * Zif.ease($gtk.args.tick_count, @random_lengths[5])).floor
    changing_button = TallButton.new(:colorful_button, cur_button_length, @cur_color, "Don't Press Me")
    @all_sprites << changing_button.containing_sprite(600, 470)
  end

  def display_interactable_button
    @all_sprites << @button.containing_sprite(600, 350)
    @all_sprites << @count_progress.containing_sprite(600, 410) if @count_progress
    label_text = "Buttons.  #{"#{@counter}/10 " if @counter.positive?}"
    label_text += (@button.is_pressed ? "It's pressed!" : 'Press one.').to_s
    @all_labels << {
      x:    600,
      y:    550,
      text: label_text
    }.merge(DEBUG_LABEL_COLOR)
  end

  def display_lag_button
    @all_sprites << @delay_button.containing_sprite(600, 240)
    @all_labels << {
      x:    600,
      y:    320,
      text: 'Test the TickTraceService (see console output)'
    }.merge(DEBUG_LABEL_COLOR)
  end

  def display_action_example
    @all_sprites << @dragon
    @all_labels << {
      x:    600,
      y:    200,
      text: 'A sprite with repeating actions:'
    }.merge(DEBUG_LABEL_COLOR)
  end
end
