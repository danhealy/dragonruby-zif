module Zif
  module Actions
    # A mixin to assist with sprite animations, to use with an object which already includes {Zif::Actions::Actionable}.
    # Under the hood, these are implemented as {Zif::Actions::Sequence}s which modify the +path+ over time.
    module Animatable
      # @return [Hash<(String, Symbol), Zif::Actions::Sequence>] Registered sequences by name.
      attr_reader :animation_sequences

      # @return [String, Symbol] Name of last run animation sequence.
      attr_reader :cur_animation

      # ------------------
      # @!group 1. Public Interface

      # Creates and registers a new {Zif::Actions::Sequence} named +named+ to animate across the +paths_and_durations+ array
      #
      # @example Register the animation for a flying Dragon (+dragon+ here is a {Zif::Sprite} or any {Zif::Actions::Animatable}) class
      #
      #  dragon.new_basic_animation(
      #    named: :fly,
      #    paths_and_durations: [
      #      ["dragon_1", 4], # This animation has 4 separate images, we go from 1 to 4 and then back to 1
      #      ["dragon_2", 4], # Hold each frame for 4 ticks
      #      ["dragon_3", 4], # The actual image exists at: app/sprites/dragon_3.png
      #      ["dragon_4", 4], # Frames 1 and 4 aren't duplicated in the sequence, so it's a fluid motion
      #      ["dragon_3", 4],
      #      ["dragon_2", 4]  # By default this repeats forever, which takes it back to 1
      #    ]
      #  )
      #
      #  # We don't have to register this sequence manually using #register_animation_sequence, the #new_basic_animation
      #  # method takes care of that for us.
      #
      #  # So now we can run this animation:
      #  dragon.run_animation_sequence(:fly)
      #
      # @param [String, Symbol] named The name of the sequence, used when calling {run_animation_sequence}
      # @param [Array<Array<String, Integer>>] paths_and_durations
      #   The frames of the animation.  Each element in this array should be like +["some_path", 4]+ where +"some_path"+
      #   is the path of the frame png image like +"sprites/#{some_path}.png"+, and the integer is the duration in ticks
      #   it should be held for.
      # @param [Integer, Symbol] repeat (see {Zif::Actions::Action::REPEAT_NAMES} for valid symbols)
      # @param [Block] block Passed to {Zif::Actions::Action#initialize}
      # @see Zif::Actions::Action#initialize
      def new_basic_animation(named:, paths_and_durations:, repeat: :forever, &block)
        actions = paths_and_durations.map do |(path, duration)|
          new_action({path: "sprites/#{path}.png"}, duration: duration, easing: :immediate, rounding: :none)
        end
        register_animation_sequence(named: named, sequence: Sequence.new(actions, repeat: repeat, &block))
      end

      # Similar to +new_basic_animation+, but for a tiled animation.
      # Use this function when you have a single image with multiple tiles, and you want to animate across them,
      # rather than a separate image per animation frame.
      #
      # This helper assumes that the spritesheet image is laid out in a single row of tiles, each of the same size
      # and with no spacing/padding between them.
      #
      # @param [String, Symbol] named The name of the sequence, used when calling {run_animation_sequence}
      # @param [String] path the path to the spritesheet image.
      # @param [Integer] width The width of each tile in the spritesheet.
      # @param [Integer] height The height of each tile in the spritesheet.
      # @param [Array<Integer>] durations The duration in ticks of each tile in the spritesheet.
      #   Can be either :tile or :source, and will target props _x, _y, _w and _h. Defaults to :tile.
      # @param [Integer, Symbol] repeat (see {Zif::Actions::Action::REPEAT_NAMES} for valid symbols)
      # @param [Block] block Passed to {Zif::Actions::Action#initialize}
      # @see Zif::Actions::Action#initialize
      def new_tiled_animation(named:, path:, width:, height:, durations:, repeat: :forever, &block)
        actions = durations.map_with_index do |duration, tile_index|
          new_action(
            {
              path:     "sprites/#{path}.png",
              source_x: 0 + (tile_index * width),
              source_y: 0,
              source_w: width,
              source_h: height
            },
            duration: duration,
            easing:   :immediate,
            rounding: :none
          )
        end
        register_animation_sequence(named: named, sequence: Sequence.new(actions, repeat: repeat, &block))
      end

      # Manually register an animation sequence.
      # If you need more control over your {Zif::Actions::Sequence} than {#new_basic_animation} provides, you can create
      # it manually, and then register it here.
      # @param [String, Symbol] named The name of the sequence, used when calling {run_animation_sequence}
      # @param [Zif::Actions::Sequence] sequence The {Zif::Actions::Sequence} itself
      def register_animation_sequence(named:, sequence:)
        # puts "Registering animation #{named} with repeat #{sequence.repeat}"

        @animation_sequences ||= {}
        @animation_sequences[named] = sequence
      end

      # Run an animation sequence which has been previously registered.
      # Since animations are mutually exclusive, this will {stop_animating} any previously running animation.
      # It will also reset the progress of the current action on the invoked sequence.
      # @param [String, Symbol] name The name of the sequence to run.
      # @see Zif::Actions::Actionable#run_action
      def run_animation_sequence(name)
        raise ArgumentError, "No animation sequence named '#{name}' registered" unless @animation_sequences[name]

        stop_animating

        @cur_animation = name
        @animation_sequences[@cur_animation].restart
        @animation_sequences[@cur_animation].cur_action.reset_start
        @animation_sequences[@cur_animation].cur_action.reset_duration
        # puts "Running animation sequence #{@cur_animation} #{@animation_sequences[@cur_animation].inspect}"

        run_action(@animation_sequences[@cur_animation])
      end

      # Stop the current animation.
      def stop_animating
        return unless @cur_animation && @animation_sequences && @animation_sequences[@cur_animation]

        # puts "Stopping animation #{@cur_animation} -> #{@animation_sequences[@cur_animation]}"
        stop_action(@animation_sequences[@cur_animation])
      end
    end
  end
end
