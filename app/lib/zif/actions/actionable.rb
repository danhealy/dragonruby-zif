module Zif
  # Inspired by https://developer.apple.com/documentation/spritekit/skaction
  # A mixin to facilitate Zif::Actions and Zif::Sequences running on this object
  module Actionable
    attr_accessor :actions, :dirty

    def run(action)
      raise ArgumentError, "Invalid action: #{action}" unless action.is_a?(Action) || action.is_a?(Sequence)

      @actions ||= []
      @actions << action
    end

    def perform_actions
      @dirty = false

      @actions ||= []
      @actions.reject! do |act|
        dirty_act = act.perform_tick
        @dirty ||= dirty_act
        act.complete?
      end
    end

    def running_actions?
      @actions ||= []
      @actions.any?
    end

    def stop_action(action)
      # puts "Stopping action #{action}: #{@actions}"
      @actions&.delete(action)
    end

    # Generic factory - sets @node
    def new_action(*args, &block)
      Action.new(self, *args, &block)
    end

    # -----------------------
    # Some example factories:
    def bounce_forever_around(y=110, distance=15, duration=5.seconds)
      Sequence.new(
        [
          new_action({y: y - distance}, duration, :smooth_step),
          new_action({y: y + distance}, duration, :smooth_step)
        ],
        :forever
      )
    end

    def fade_out_and_in_forever(duration=1.seconds)
      Sequence.new([fade_out(duration), fade_in(duration)], :forever)
    end

    def fade_out(duration=3.seconds, &block)
      new_action({a: 0}, duration, &block)
    end

    def fade_in(duration=3.seconds, &block)
      new_action({a: 255}, duration, &block)
    end
  end
end
