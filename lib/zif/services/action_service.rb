module Zif
  # This just facilitates keeping track of and running Actionables that need updating every tick.
  # Specifically, when #run_all_actions is invoked this will call #perform_actions on all Actionable objects which have
  # been previously registered using #register_actionable.
  class ActionService
    def initialize
      reset_actionables
    end

    def reset_actionables
      @actionables = []
    end

    def register_actionable(actionable)
      # if actionable.is_a?(Zif::Actionable)
      #   puts "Zif::ActionService#register_actionable: registered #{actionable}"
      # else
      #   raise "Zif::ActionService#register_actionable: #{actionable} is not a Zif::Actionable"
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
      @actionables.each(&:perform_actions)
    end
  end
end
