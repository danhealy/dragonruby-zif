module Zif
  module Actions
    # Inspired by https://developer.apple.com/documentation/spritekit/skaction
    #
    # A mixin to facilitate {Zif::Actions::Action}s and {Zif::Actions::Sequence}s running on this object
    module Actionable
      # @return [Array<Zif::Actions::Action, Zif::Actions::Sequence>] The list of running {Zif::Actions::Action}s and {Zif::Actions::Sequence}s
      attr_reader :actions

      # @return [Boolean] Did any of the running actions change this object this tick?
      attr_reader :dirty

      # ------------------
      # @!group 1. Public Interface

      # Add an action to the list of actions to run.
      # @param [Zif::Actions::Action, Zif::Actions::Sequence] action The action or sequence to run
      def run_action(action)
        raise ArgumentError, "Invalid action: #{action}" unless action.is_a?(Action) || action.is_a?(Sequence)

        @actions ||= []
        @actions << action
      end

      # Stop a running action.
      # @param [Zif::Actions::Action, Zif::Actions::Sequence] action The action or sequence to stop.  Must be present in {actions}
      def stop_action(action)
        # puts "Stopping action #{action}: #{@actions}"
        @actions&.delete(action)
      end

      # @return [Boolean] Are any actions running?
      def running_actions?
        @actions ||= []
        @actions.any?
      end

      # A convenience factory for a new {Zif::Actions::Action} targeting +self+ as the +node+.
      # Sends other params to {Zif::Actions::Action#initialize}
      # @see Zif::Actions::Action#initialize
      #
      # @return [Zif::Actions::Action] Newly created Action targeted at +self+
      def new_action(*args, &block)
        Action.new(self, *args, &block)
      end

      # Create an no-op {Zif::Actions::Action} targeting +self+ - just a wait and a callback.
      # @param [Integer] wait The number of ticks to wait.
      # @param [Integer, Symbol] repeat (see {Zif::Actions::Action::REPEAT_NAMES} for valid symbols)
      def delayed_action(wait, repeat: 1, &block)
        new_action({}, duration: wait, easing: :linear, rounding: :round, repeat: repeat, &block)
      end

      # ------------------
      # @!group 2. Example Factories - Use these as inspiration for creating custom {Zif::Actions::Action}s

      # Example factory
      # Returns a new {Zif::Actions::Sequence} which eases the sprite up and down around +y+ at some +distance+ over
      # +duration+. Repeats forever.
      # @param [Integer] y The center Y position to bounce around
      # @param [Integer] distance The distance from +y+ it will travel above and below
      # @param [Integer] duration Number of ticks it will take to travel to the top or bottom
      # @return [Zif::Actions::Sequence]
      def bounce_forever_around(y: 110, distance: 15, duration: 5.seconds)
        Sequence.new(
          [
            new_action({y: y - distance}, duration: duration, easing: :smooth_step),
            new_action({y: y + distance}, duration: duration, easing: :smooth_step)
          ],
          repeat: :forever
        )
      end

      # Example factory
      # Returns a new {Zif::Actions::Sequence} which combines {fade_in} and {fade_out} forever
      # @param [Integer] duration Number of ticks it takes to fade in or out fully
      # @return [Zif::Actions::Sequence]
      def fade_out_and_in_forever(duration=1.seconds)
        Sequence.new([fade_out(duration), fade_in(duration)], repeat: :forever)
      end

      # Example factory
      # Returns a new {Zif::Actions::Action} which eases the sprite's +a+ alpha to +0+ over +duration+
      # @param [Integer] duration Number of ticks it takes to fade out fully
      # @param [Block] block Passed to {Zif::Actions::Action#initialize}
      # @return [Zif::Actions::Action]
      # @see Zif::Actions::Action#initialize
      def fade_out(duration=3.seconds, &block)
        new_action({a: 0}, duration: duration, &block)
      end

      # Example factory
      # Returns a new {Zif::Actions::Action} which eases the sprite's +a+ alpha to +255+ over +duration+
      # @param [Integer] duration Number of ticks it takes to fade in fully
      # @param [Block] block Passed to {Zif::Actions::Action#initialize}
      # @return [Zif::Actions::Action]
      # @see Zif::Actions::Action#initialize
      def fade_in(duration=3.seconds, &block)
        new_action({a: 255}, duration: duration, &block)
      end

      # ------------------
      # @!group 3. Private-ish methods

      # @api private
      def perform_actions
        @dirty = false

        @actions ||= []
        @actions.each do |act|
          dirty_act = act.perform_tick
          @dirty ||= dirty_act
        end
        @actions.reject!(&:complete?)
      end
    end
  end
end
