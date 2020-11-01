module Zif
  # Inspired by https://developer.apple.com/documentation/spritekit/skaction
  # A sequence of Zif::Actions that can be repeated
  # Meant to be applied to an object using the Actionable mixin
  class Sequence
    include Zif::Serializable
    attr_accessor :action_index, :sub_actions, :repeat, :cur_repeat, :sub_repeats, :callback, :node

    def initialize(actions, repeat=1, &block)
      actions.each do |action|
        raise ArgumentError, "Invalid action: #{action}" unless action.is_a? Action
      end

      @callback = block if block_given?

      @sub_actions = actions
      @repeat = Action::REPEAT_NAMES[repeat] || repeat

      restart
      setup_action
    end

    def restart
      @action_index = 0
      @cur_repeat = @repeat
      @sub_repeats = @sub_actions.map(&:repeat).freeze
    end

    def perform_tick
      # puts "Sequence#perform_tick"
      @dirty = cur_action.perform_tick

      next_action if cur_action.complete?
      perform_callback if complete? && @callback

      @dirty
    end

    def cur_action
      @sub_actions[@action_index]
    end

    def setup_action
      # puts "Sequence#setup_action #{@action_index}"
      cur_action.repeat = @sub_repeats[@action_index]
      cur_action.reset_start
      cur_action.reset_duration
    end

    def next_action
      # puts "Sequence#next_action"
      @action_index = (@action_index + 1) % @sub_actions.length
      @repeat -= 1 if @action_index.zero?

      setup_action unless complete?
    end

    def complete?
      # puts "Complete action! - #{@node.class}" if @repeat.zero?
      @repeat.zero?
    end

    def perform_callback
      @callback.call(self)
      # puts "Sequence#perform_callback: Callback triggered"
    end
  end
end
