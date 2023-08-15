module Zif
  module Actions
    # Inspired by https://developer.apple.com/documentation/spritekit/skaction
    #
    # A sequence of {Zif::Actions::Action}s that can be repeated as a whole
    #
    # Meant to be applied to an object using the {Zif::Actions::Actionable} mixin, just like {Zif::Actions::Action}
    class Sequence
      include Zif::Serializable

      # @return [Integer] Index of the current action for this sequence
      attr_reader :action_index

      # @return [Array<Zif::Actions::Action>] The actions this sequence runs through
      attr_accessor :sub_actions

      # @return [Integer] The number of times this Sequence should repeat
      attr_accessor :repeat

      # @return [Integer] The number of repeat iterations left
      attr_accessor :cur_repeat

      # @return [Array<Integer>] The number of times each Action in {sub_actions} should repeat before moving on
      attr_reader :sub_repeats

      # @return [Proc] A callback to run at the end of the entire sequence
      attr_accessor :callback

      # ------------------
      # @!group 1. Public Interface

      # @param [Array<Zif::Actions::Action>] actions The ordered list of actions in this sequence
      # @param [Integer, Symbol] repeat (see {Zif::Actions::Action::REPEAT_NAMES} for valid symbols)
      # @param [Block] block Callback to perform when the entire sequence completes
      def initialize(actions, repeat: 1, &block)
        actions.each do |action|
          raise ArgumentError, "Invalid action: #{action}" unless action.is_a? Action
        end

        @callback = block if block_given?

        @sub_actions = actions
        @repeat = Action::REPEAT_NAMES[repeat] || repeat

        restart
        setup_action
      end

      # Resets the state of the sequence back to the initialized state.
      def restart
        @action_index = 0
        @cur_repeat = @repeat
        @sub_repeats = @sub_actions.map(&:repeat).freeze
      end

      # @return [Zif::Actions::Action] the current Action in this sequence.
      def cur_action
        @sub_actions[@action_index]
      end

      # @return [Boolean] Has this sequence run out of repeat iterations?
      def complete?
        # puts "Complete action! - #{@node.class}" if @repeat.zero?
        @cur_repeat.zero?
      end

      # ------------------
      # @!group 2. Private-ish methods

      # Resets the current action's parameters, so it is fresh and ready to run.
      # @api private
      def setup_action
        # puts "Sequence#setup_action #{@action_index}"
        cur_action.repeat = @sub_repeats[@action_index]
        cur_action.reset_start
        cur_action.reset_duration
      end

      # Advances the sequence to the next action.
      # @api private
      def next_action
        # puts "Sequence#next_action"
        @action_index = (@action_index + 1) % @sub_actions.length
        @cur_repeat -= 1 if @action_index.zero?

        setup_action unless complete?
      end

      # Calls the current action's {Zif::Actions::Action#perform_tick}
      # Conditionally advances to the next action and performs the callback.
      # @return [Boolean] Did the current action cause a change on the node during this tick?
      # @api private
      def perform_tick
        # puts "Sequence#perform_tick"
        @dirty = cur_action.perform_tick

        next_action if cur_action.complete?
        perform_callback if complete? && @callback

        @dirty
      end

      # Calls the {callback} on +self+
      # @api private
      def perform_callback
        @callback.call(self)
        # puts "Sequence#perform_callback: Callback triggered"
      end
    end
  end
end
