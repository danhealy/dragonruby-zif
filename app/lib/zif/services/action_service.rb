module Zif
  # This just facilitates keeping track of and running Actionables that need updating every tick.
  # Specifically, when #run_all_actions is invoked this will call #perform_actions on all Actionable objects which have
  # been previously registered using #register_actionable.
  class ActionService
    attr_accessor :actionables

    def initialize
      reset_actionables
    end

    def reset_actionables
      @actionables = []
    end

    def register_actionable(actionable)
      # if actionable.is_a?(Zif::Actions::Actionable)
      #   puts "Zif::ActionService#register_actionable: registered #{actionable}"
      # else
      #   raise "Zif::ActionService#register_actionable: #{actionable} is not a Zif::Actions::Actionable"
      # end
      @actionables << actionable
    end

    def remove_actionable(actionable)
      @actionables.delete(actionable)
    end

    def promote_actionable(actionable)
      @actionables.unshift(remove_actionable(actionable))
    end

    def demote_actionable(actionable)
      @actionables.push(remove_actionable(actionable))
    end

    def run_all_actions
      actionables_count = @actionables&.length

      return false unless actionables_count&.positive?

      # Avoid blocks here.
      idx = 0
      while idx < actionables_count
        @actionables[idx].perform_actions
        idx += 1
      end

      true
    end
  end
end
