module ExampleApp
  # An example of all the UI elements
  # Also demonstrates usage of services:
  # - Input service (handles the two button Clickables)
  # - Action service (handles actions "tweening"/"easing" of the Dragon sprite)
  # - Sprite registry (provides a prototype to construct the Dragon sprite by name)
  # - TickTrace service (will get triggered when the "Simulate Lag" button is clicked, reports slow sections of code)
  class UISample < ZifExampleScene
    attr_accessor :cur_color, :button, :counter, :count_progress, :random_lengths, :metal

    DEBUG_LABEL_COLOR = { r: 255, g: 255, b: 255 }.freeze

    def initialize
      # See ZifExampleScene for info on super and next_scene
      super
      @next_scene = :load_world
    end

    # #prepare_scene and #unload_scene are called by Game before the scene gets run for the first time, and after it
    # detects a scene change has been requested, respectively
    # This is a good spot to set up services, and manually control the global $gtk.args.outputs
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Layout/LineLength
    def prepare_scene
      super
      mark('#prepare_scene: begin')

      # Just some shared random numbers
      @random_lengths = Array.new(10) { rand(160) + 40 }

      # Choose a random color to use for the various elements.
      change_color

      # -------------------------------------------------------------------------
      # Panels

      @glass = GlassPanel.new(600, 600)
      @glass.x = 550
      @glass.y = 60
      @glass_label = { x: 600, y: 685, text: "Glass panel cuts: #{@glass.cuts}" }.merge(DEBUG_LABEL_COLOR)

      cur_w = 64 + 200 + (200 * Zif.ease($gtk.args.tick_count, @random_lengths[1])).floor
      cur_h = 64 + 200 + (200 * Zif.ease($gtk.args.tick_count, @random_lengths[2])).floor
      @metal = MetalPanel.new(cur_w, cur_h, 'Hello World', @cur_color)
      @metal.x = 20
      @metal.y = 160
      @metal_label = {
        x:    20,
        y:    660,
        text: 'Scaling custom 9-slice'
      }.merge(DEBUG_LABEL_COLOR)

      # This is the center gray "cutout" inside the metal panel
      @cutout = MetalCutout.new(cur_w - 50, cur_h - 100)
      @cutout.x = 20 + 25
      @cutout.y = 160 + 25

      @wrapping_label = FutureLabel.new(
        "Lorem ipsum\ndolor sit\namet,\nconsectetur adipiscing\n\nelit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
        size:      -2,
        alignment: :left,
        blend:     :alpha
      ).tap do |l|
        l.x = @cutout.x + 10
        l.y = @cutout.y + @cutout.h - 10
        l.r = 0
        l.g = 0
        l.b = 0
        l.a = 255
      end

      # -------------------------------------------------------------------------
      # Progress bars
      @count_progress = ProgressBar.new(:count_progress, 400, 0, @cur_color)
      @count_progress.x = 600
      @count_progress.y = 410
      @count_progress.view_actual_size!
      @count_progress.hide

      @prog = ProgressBar.new(:progress, 150, 0.5, @cur_color)
      @prog.x = 600
      @prog.y = 580
      @prog_label = {
        x:    600,
        y:    640,
        text: 'Progress bar: width 150, progress 50%'
      }.merge(DEBUG_LABEL_COLOR)

      # -------------------------------------------------------------------------
      # Buttons
      #
      # TwoStageButton (which TallButton inherits from) accepts a block in the constructor
      # The block is executed when the button is registered as a clickable, and it receives the mouse up event
      # You can give sprites callback functions for on_mouse_down, .._changed (mouse is moving while down), and .._up
      # In this case, the TwoStageButton initializer sets on_mouse_down and on_mouse_changed automatically
      # This is because as a button, it needs to update whether or not it is_pressed based on the mouse point.
      @counter = 0
      @button = TallButton.new(:static_button, 300, :blue, 'Press Me', 2) do |point|
        # You should check the state of the button as it's possible to click down on the button, but then move the mouse
        # away and let go of the mouse away from the button
        # The state is updated automatically in the on_mouse_changed callback created by the TwoStageButton initializer
        if @button.is_pressed
          puts "UISample: Button on_mouse_up, #{point}: mouse inside button. Pressed!"
          @counter += 1

          @count_progress.show if @counter == 1
          @count_progress.progress = @counter / 10.0

          @load_next_scene_next_tick = true if @counter >= 10

          @dragon.run_animation_sequence(:coast)
        else
          puts "UISample: Button on_mouse_up, #{point}: mouse outside button. Not pressed."
        end
      end
      @button.x = 600
      @button.y = 350
      @button_label = {
        x:    600,
        y:    550,
        text: 'Buttons.'
      }.merge(DEBUG_LABEL_COLOR)

      @form_field = FormField.new(x: 20, y: 115, label: 'Text Input: ', char_width: 28)
      @form_field_status = {
        x:    @form_field.x,
        y:    @form_field.y - 5,
        text: "Form Field Has Focus: #{@form_field.input.focused?}"
      }.merge(DEBUG_LABEL_COLOR)

      # We need a full-screen overlay which does not absorb clicks to test for losing focus on the form field
      @focus_check = FocusCheck.new
      @focus_check.on_mouse_down = ->(_sprite, _point) { @form_field.lose_focus }

      @delay_button = TallButton.new(:delay_button, 300, :red, 'Simulate Lag', 2) do |_point|
        mark_and_print('delay_button: Button was clicked - demonstrating Tick Trace service')
        sleep(0.5)
        mark_and_print('delay_button: Woke up from 500ms second nap')
      end
      @delay_button.x = 600
      @delay_button.y = 240

      # Using #tap is common ruby pattern.  It just yields the object to the given block and then returns the object.
      # It's an alternative to the pattern of setting a @ivar = Foo.new .. and then repetitively setting @ivar.bar = baz
      @changing_button = TallButton.new(:colorful_button, 20, @cur_color, "Don't Press Me").tap do |b|
        b.x = 600
        b.y = 470
      end

      @changing_button.run_action(
        Zif::Actions::Sequence.new(
          [
            @changing_button.new_action({width: 420}, duration: 2.seconds, easing: :linear),
            @changing_button.new_action({width: 20},  duration: 2.seconds, easing: :linear)
          ],
          repeat: :forever
        )
      )

      # -------------------------------------------------------------------------
      # Basic sprites
      #
      # Create a sprite from a prototype registered in the Sprite Registry service
      # This returns a Zif::Sprite with the proper w/h/path settings
      @dragon = $game.services[:sprite_registry].construct('dragon_1').tap do |s|
        s.x = 600
        s.y = 100
      end

      # Run some action sequences on this sprite
      @dragon.run_action(@dragon.fade_out_and_in_forever)
      @dragon.run_action(
        Zif::Actions::Sequence.new(
          [
            # Move from starting position to 1000x over 1 second, starting slowly, then flip the sprite at the end
            @dragon.new_action({x: 1000}, duration: 1.seconds, easing: :smooth_start) do
              @dragon.flip_horizontally = true
            end,
            # Move from the new position (1000x) back to the start 600x over 2 seconds, stopping slowly, then flip again
            @dragon.new_action({x: 600}, duration: 2.seconds, easing: :smooth_stop) do
              @dragon.flip_horizontally = false
            end
          ],
          repeat: :forever
        )
      )

      @dragon.new_basic_animation(
        named:               :fly,
        paths_and_durations: 1.upto(4).map { |i| ["dragon_#{i}", 4] } + 3.downto(2).map { |i| ["dragon_#{i}", 4] }
      )

      # This is an example of a one-off animation which returns to a looping animation when complete
      @dragon.new_basic_animation(
        named:               :coast,
        paths_and_durations: 1.upto(4).map { |i| ["dragon_#{i}", 12] } + 3.downto(2).map { |i| ["dragon_#{i}", 12] },
        repeat:              2
      ) do
        @dragon.run_animation_sequence(:fly)
      end

      @dragon.run_animation_sequence(:fly)

      @animation_label = {
        x:    600,
        y:    200,
      }.merge(DEBUG_LABEL_COLOR)

      # -------------------------------------------------------------------------
      # Info Labels

      $gtk.args.outputs.static_labels << [
        @glass_label,
        @prog_label,
        @button_label,
        @metal_label,
        @form_field_status,
        {
          x:    600,
          y:    320,
          text: 'Test the TickTraceService (see console output)'
        }.merge(DEBUG_LABEL_COLOR),
        @animation_label
      ]

      # -------------------------------------------------------------------------
      # You have to explicity tell the action and input services which sprites to handle
      # Clickables must be registered with the input service to be tested when a click is detected
      # Actionables must be registered with the action service to be notified to update based on the running Actions
      $game.services[:action_service].register_actionable(@changing_button)
      $game.services[:action_service].register_actionable(@dragon)
      $game.services[:input_service].register_clickable(@focus_check)
      $game.services[:input_service].register_clickable(@button)
      $game.services[:input_service].register_clickable(@delay_button)
      $game.services[:input_service].register_clickable(@form_field)
      $game.services[:input_service].register_key_pressable(@form_field.input)

      # If you're retaining a reference to sprites that will be displayed across every tick, it's best for performance
      # reasons if you use the static_sprites output.  You can always set the alpha of a sprite to zero to temporarily
      # hide it.  This technique is used with @cutout and @count_progress, etc.
      # So we set static_sprites here in #prepare_scene rather than #perform_tick because it only needs to happen once.
      $gtk.args.outputs.static_sprites << [
        # --- Panels ---
        @glass,
        @metal,
        # Make sure the cutout is after metal, since it's on top.
        @cutout,
        # --- Input field ---
        @form_field,
        # --- Buttons ---
        @button,
        @delay_button,
        @changing_button,
        # --- Progress Bars ---
        @count_progress,
        @prog,
        # --- Sprites ---
        @dragon
      ]
      mark('#prepare_scene: complete')
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Layout/LineLength

    def change_color
      @cur_color = %i[blue green red white yellow].sample
      [
        @changing_button,
        @metal,
        @prog,
        @count_progress
      ].each do |color_changing|
        color_changing&.change_color(@cur_color)
      end
    end

    def color_should_change?
      ($gtk.args.tick_count % @random_lengths[0]).zero?
    end

    def perform_tick
      mark('#perform_tick: begin')
      $gtk.args.outputs.background_color = [0, 0, 0, 0]

      change_color if color_should_change?

      update_metal_panel
      update_glass_panel
      update_progress_bar
      update_interactable_button
      update_form_field_status

      mark('#perform_tick: finished updates')
      finished = super

      mark('#perform_tick: finished super')
      return finished if finished

      @force_next_scene ||= @load_next_scene_next_tick # rubocop:disable Naming/MemoizedInstanceVariableName
    end

    def update_metal_panel
      mark('#update_metal_panel: begin')
      cur_w = 64 + 200 + (200 * Zif.ease($gtk.args.tick_count, @random_lengths[1])).floor
      cur_h = 64 + 200 + (200 * Zif.ease($gtk.args.tick_count, @random_lengths[2])).floor

      @metal.resize(cur_w, cur_h)
      @metal_label.text = "Scaling custom 9-slice: #{cur_w}x#{cur_h}"

      if (cur_w > 75) && (cur_h > 120)
        @cutout.show
        @cutout.resize(cur_w - 50, cur_h - 100)
        @wrapping_label.y = @cutout.y + @cutout.h - 10
        $gtk.args.outputs.labels << @wrapping_label.wrap(@cutout.w - 20).take((@cutout.h - 20).idiv(18))
      else
        @cutout.hide
      end
      mark('#update_metal_panel: complete')
    end

    def update_glass_panel
      mark('#update_glass_panel: begin')
      cuts = ('%04b' % (($gtk.args.tick_count / 60) % 16)).chars.map { |bit| bit == '1' }
      @glass.change_cuts(cuts)
      @glass_label.text = "Glass panel cuts: #{@glass.cuts}"
      @animation_label.text = "A sprite (animating: #{@dragon.cur_animation}) with repeating actions:"
      mark('#update_glass_panel: complete')
    end

    def update_progress_bar
      mark('#update_progress_bar: begin')
      cur_progress       = (0.5 + 0.5 * Zif.ease($gtk.args.tick_count, @random_lengths[3])).round(4)
      cur_progress_width = 150 + (50 * Zif.ease($gtk.args.tick_count, @random_lengths[4])).floor

      @prog.progress = cur_progress
      @prog.resize_width(cur_progress_width)
      @prog.view_actual_size!

      @prog_label.text = "Progress bar: width #{cur_progress_width}, progress #{(cur_progress * 100).round}%"
      mark('#update_progress_bar: complete')
    end

    def update_interactable_button
      mark('#update_interactable_button: begin')
      label_text = "Buttons.  #{"#{@counter}/10 " if @counter.positive?}"
      label_text += (@button.is_pressed ? "It's pressed!" : 'Press one.').to_s
      @button_label.text = label_text
      mark('#update_interactable_button: complete')
    end

    def update_form_field_status
      mark('#update_form_field_status: begin')
      @form_field_status.text = "Form Field Has Focus: #{@form_field.input.focused?}"
      mark('#update_form_field_status: complete')
    end
  end
end
