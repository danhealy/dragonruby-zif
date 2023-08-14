module Zif
  module Actions
    # Inspired by https://developer.apple.com/documentation/spritekit/skaction
    #
    # and Squirrel Eiserloh's GDC talk on nonlinear transformations https://www.youtube.com/watch?v=mr5xkf6zSzk
    #
    # A transition of a set of attributes over time using an easing function (aka tweening, easing)
    # Meant to be applied to an object using the {Zif::Actions::Actionable} mixin
    class Action
      include Zif::Serializable

      # @return [Hash] The start conditions for the keys referenced in {finish}
      attr_accessor :start

      # @return [Hash<Symbol, Object>]
      #   Key-value pair of attributes being acted upon, and their final state.
      #   The +Symbol+ keys must represent a getter *and* setter on the node.  These can be traditional attributes defined
      #   using +attr_accessor+, or manually defined e.g. +def x=(new_x)+ ..
      attr_accessor :finish

      # @return [Object] An object being followed.  Reset {finish} based on this object's values each tick.
      attr_accessor :follow

      # @return [Proc] A callback to run at the end of the action
      attr_accessor :callback

      # @return [Symbol] Method name of the easing function to apply over the duration, (see {Action::EASING_FUNCS})
      attr_accessor :easing

      # @return [Numeric] The number of times this will repeat
      attr_accessor :repeat

      # @return [Integer] The number of ticks it will take to reach the finish condition
      attr_accessor :duration

      # @return [Integer] Set to +$gtk.args.tick_count - 1+ when created / started
      attr_accessor :started_at

      # @return [Boolean] True if this action caused a change on the node during this tick
      attr_reader :dirty

      # @return [Symbol] The rounding strategy for values being adjusted during the action (see {Action::ROUNDING_FUNCS})
      attr_accessor :rounding

      # @return [Boolean] Set this to +true+ to override the normal duration and complete this iteration on next tick
      attr_accessor :finish_early

      # A list of convenient names for repeat counts
      REPEAT_NAMES = {
        once:    1,
        twice:   2,
        thrice:  3,
        forever: Float::INFINITY,
        always:  Float::INFINITY
      }.freeze

      EASING_FUNCS = %i[
        immediate linear flip
        smooth_start smooth_start3 smooth_start4 smooth_start5
        smooth_stop smooth_stop3 smooth_stop4 smooth_stop5
        smooth_step smooth_step3 smooth_step4 smooth_step5
      ].freeze

      ROUNDING_FUNCS = %i[ceil floor round none].freeze

      # ------------------
      # @!group 1. Public Interface

      # @example Detailed explanation
      #   # dragon is a Zif::Sprite (and therefore a Zif::Actions::Actionable, but any class that includes Actionable
      #   # can receive an Action like this.  A non-Sprite example is Zif::Layers::Camera).
      #   # The initial x position is being set to 200 here:
      #   dragon.x = 200
      #
      #   # The ActionService is essential for this.  Every tick, it's going to check the list of registered Actionable
      #   # objects for any running Actions.  If it has one, it will tell that Action a tick has passed.  The Action
      #   # then knows to update the node it was run on, based on the conditions specified by this constructor.
      #   #
      #   # For this example, assume that Zif::Services::ActionService has been set up and is available at:
      #   #   $game.services.named(:action_service)
      #   # Now we need to tell it that our dragon needs to be checked every tick for actions.  This only needs to be
      #   # done once, it will stay in the list of Actionables to check until removed.
      #   $game.services.named(:action_service).register_actionable(dragon)
      #
      #   # Create an action, the plan is to move the dragon to x == 300 over 2 seconds
      #   # Notice that we don't have to specify the start conditions (x==200).
      #   # Action will save the start conditions when created.
      #   move_to_300_action = Zif::Actions::Action.new(
      #     dragon,
      #     {x: 300},
      #     duration: 2.seconds,
      #     easing: :linear,
      #     rounding: :round
      #   )
      #
      #   # A plan is no good without execution.  The dragon is a Zif::Sprite, so it has the methods defined by
      #   # Zif::Actions::Actionable, including #run_action.  This tells the action it's starting now (on this tick).
      #   dragon.run_action(move_to_300_action)
      #
      #   # Now we wait.  Every tick, ActionService will inspect dragon, it will find the running action, and slowly
      #   # move the dragon to x == 300.  Because the initial condition is x == 200, and the action should run for 2
      #   # seconds, and the easing function is linear, that means on each tick it needs to move the dragon to:
      #   #
      #   # 200 + (ticks_since_run * (300 - 200)).fdiv(2*60)
      #   #
      #   # So, next tick (ticks_since_run==1) it will be at:
      #   #
      #   # 200 + ((1 * 100) / 120) = 200.833...
      #   #
      #   # We've specified :round as the rounding function, so this gets rounded to 201.
      #   #
      #   # After 120 ticks, the dragon will be at x == 300.  The Action recognizes it's complete and removes itself
      #   # from the list of running actions on dragon.  If we had passed a block to Zif::Actions::Action.new, that
      #   # block would execute at this point.
      #
      #
      # @param [Zif::Actions::Actionable] node The node (Actionable object) the action should be run on
      # @param [Hash] finish A hash representing the end state of the node at the end of the action.
      # @note
      #   Important! Each key in the +finish+ hash must map to an accessible attribute on the +node+.
      #
      #   (+:key+ getter and +:key=+ setter, as you get with an +attr_accessor+, but could also be defined manually.
      #   See {Zif::Layers::Camera#pos_x=} for an example of a manually defined Actionable attribute)
      # @param [Object] follow Another object to follow.  The finish condition will be reset each tick by the follow
      #   object's value for the provided keys.
      # @param [Numeric] duration
      # @param [Symbol] easing (see {Action::EASING_FUNCS})
      # @param [Symbol] rounding (see {Action::ROUNDING_FUNCS})
      # @param [Integer, Symbol] repeat (see {Action::REPEAT_NAMES} for valid symbols)
      # @param [Block] block Callback to perform when action completes
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Layout/LineLength
      def initialize(
        node,
        finish,
        follow:   nil,
        duration: 1.seconds,
        easing:   :linear,
        rounding: :round,
        repeat:   1,
        &block
      )
        unless node.is_a? Zif::Actions::Actionable
          raise ArgumentError, "Invalid node: #{node}, expected a Zif::Actions::Actionable"
        end

        @node = node
        @follow = follow

        unless EASING_FUNCS.include? easing
          raise ArgumentError, "Invalid easing function: '#{easing}'.  Must be in #{EASING_FUNCS}"
        end

        @easing = easing

        unless ROUNDING_FUNCS.include? rounding
          raise ArgumentError, "Invalid rounding function: '#{rounding}'.  Must be in #{ROUNDING_FUNCS}"
        end

        @rounding = rounding

        @start = {}
        finish.each_key do |key|
          [key, "#{key}="].each do |req_meth|
            unless @node.respond_to?(req_meth)
              raise ArgumentError, "Invalid finish condition: #{@node} doesn't have a method named '##{req_meth}'"
            end
          end
        end

        if @follow
          finish.each do |key, val|
            unless val.is_a? Symbol
              raise ArgumentError, "You provided an object to follow. A Symbol was expected instead of '#{val}' (#{val.class}) for the key-value pair (#{key}: #{val}) in the finish condition. Action needs this symbol to be the name of a method on the followed object (#{@follow.class})"
            end
            unless @follow.respond_to?(val)
              raise ArgumentError, "You provided an object to follow, but it doesn't respond to '##{val}' (for finish '#{key}')"
            end
          end
        end

        @finish = finish
        @finish_early = false
        reset_start

        @repeat = REPEAT_NAMES[repeat] || repeat
        @duration = [duration.to_i, 1].max # in ticks

        @callback = block if block_given?

        # puts "Action: #{@start} -> #{@finish} in #{@duration} using #{@easing}.  Block present? #{block_given?}"
        reset_duration
      end
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Layout/LineLength

      # Recalculates the start conditions for the action based on node state.  Easing is calculated as difference
      # between start and finish conditions over time.
      def reset_start
        @finish.each_key do |key|
          @start[key] = @node.send(key)
        end
      end

      # Resets {started_at} to the current tick
      def reset_duration
        @started_at = $gtk.args.tick_count - 1
      end

      # Forces the easing to finish on the next {perform_tick}, ignoring duration
      def finish_early!
        @finish_early = true
      end

      # @return [Float] 0.0 -> 1.0 Percentage of duration passed.
      def progress
        @finish_early ? 1.0 : ($gtk.args.tick_count - @started_at).fdiv(@duration)
      end

      # @return [Boolean] True if {progress} is 1.0
      def iteration_complete?
        progress >= 1.0
      end

      # @return [Boolean] True if there are no more {repeat}s left on this action
      def complete?
        # puts "Action#complete?: Action complete! #{self.inspect} #{@node.class}" if @repeat.zero?
        @repeat.zero?
      end

      # ------------------
      # @!group 2. Private-ish methods

      # Performs one tick's worth of easing on all attributes specified by {finish} conditions. Sets {dirty} to true if
      # something changed. Calls {callback} if finished.
      # @return [Boolean] {dirty}
      # @api private
      def perform_tick
        @dirty = false
        @finish.each do |key, val|
          target = @follow ? @follow.send(val) : val
          start = @node.send(key)
          # puts "  easing #{key} #{start} -> #{val}"
          if start.is_a? Numeric
            change_to = ease(@start[key], target)
            change_to = change_to.send(@rounding) unless @rounding == :none
          else
            change_to = target
          end
          @dirty = true if start != change_to

          # puts "  assigning #{key}= #{change_to}"
          @node.send("#{key}=", change_to)
        end

        # puts "iteration_complete? : #{iteration_complete?}, duration: #{@duration}, repeat: #{@repeat}"

        if iteration_complete?
          @finish_early = false
          @repeat -= 1
          reset_duration
        end

        perform_callback if @callback && complete?

        @dirty
      end

      # @param [Numeric] start_val
      # @param [Numeric] finish_val
      # @return [Numeric] Returns a value between +start_val+ and +finish_val+ based on function specified by {easing}
      # @api private
      def ease(start_val, finish_val)
        ((finish_val - start_val) * send(@easing)) + start_val
      end

      # Calls {callback} with self
      # @api private
      def perform_callback
        # puts "Action#perform_callback: Callback triggered"
        @callback.call(self)
      end

      # ------------------
      # @!group 3. Easing Functions
      # Insprired by https://www.youtube.com/watch?v=mr5xkf6zSzk

      # @note Meant to be called indirectly via setting {easing}
      def immediate(_x=nil)
        1.0
      end

      # @note Meant to be called indirectly via setting {easing}
      def linear(x=progress)
        x
      end

      # @note Meant to be called indirectly via setting {easing}
      def flip(x=progress)
        1 - x
      end

      # @note Meant to be called indirectly via setting {easing}
      def mix(a=:linear, b=:linear, rate=0.5, x=progress)
        (1 - rate) * send(a, x) + rate * send(b, x)
      end

      # @note Meant to be called indirectly via setting {easing}
      def crossfade(a=:linear, b=:linear, x=progress)
        mix(a, b, x, x)
      end

      # @note Meant to be called indirectly via setting {easing}
      def smooth_start(x=progress)
        x * x
      end

      # @note Meant to be called indirectly via setting {easing}
      def smooth_start3(x=progress)
        x * x * x
      end

      # @note Meant to be called indirectly via setting {easing}
      def smooth_start4(x=progress)
        x * x * x * x * x
      end

      # @note Meant to be called indirectly via setting {easing}
      def smooth_start5(x=progress)
        x * x * x * x * x * x
      end

      # @note Meant to be called indirectly via setting {easing}
      def smooth_stop(x=progress)
        flip(smooth_start(flip(x)))
      end

      # @note Meant to be called indirectly via setting {easing}
      def smooth_stop3(x=progress)
        flip(smooth_start3(flip(x)))
      end

      # @note Meant to be called indirectly via setting {easing}
      def smooth_stop4(x=progress)
        flip(smooth_start4(flip(x)))
      end

      # @note Meant to be called indirectly via setting {easing}
      def smooth_stop5(x=progress)
        flip(smooth_start5(flip(x)))
      end

      # @note Meant to be called indirectly via setting {easing}
      def smooth_step(x=progress)
        crossfade(:smooth_start, :smooth_stop, x)
      end

      # @note Meant to be called indirectly via setting {easing}
      def smooth_step3(x=progress)
        crossfade(:smooth_start3, :smooth_stop3, x)
      end

      # @note Meant to be called indirectly via setting {easing}
      def smooth_step4(x=progress)
        crossfade(:smooth_start4, :smooth_stop4, x)
      end

      # @note Meant to be called indirectly via setting {easing}
      def smooth_step5(x=progress)
        crossfade(:smooth_start5, :smooth_stop5, x)
      end
    end
  end
end
