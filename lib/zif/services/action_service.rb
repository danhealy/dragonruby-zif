module Zif
  module Services
    # This service facilitates keeping track of and running {Zif::Action::Actionable}s that need updating every tick.
    #
    # Specifically, every tick {Zif::Game} will invoke {#run_all_actions} on this service.
    # In turn, this calls {Zif::Action::Actionable#perform_actions} on all {Zif::Action::Actionable}s objects which have
    # been previously registered using {#register_actionable}.
    # @see Zif::Action::Actionable
    class ActionService
      # @return [Array<Zif::Action::Actionable>] The list of {Zif::Action::Actionable}s to check each tick
      attr_reader :actionables

      # ------------------
      # @!group 1. Public Interface

      # Calls {reset_actionables}
      def initialize
        reset_actionables
      end

      # Resets the {actionables} array.
      def reset_actionables
        @actionables = []
      end

      # Adds an {Zif::Actions::Actionable} to the {actionables} array.
      # @param [Zif::Actions::Actionable] actionable
      def register_actionable(actionable)
        unless actionable.is_a?(Zif::Actions::Actionable)
          raise ArgumentError, 'Zif::Services::ActionService#register_actionable:' /
                               " #{actionable} is not a Zif::Actions::Actionable"
        end

        @actionables << actionable
      end

      # Removes an {Zif::Actions::Actionable} from the {actionables} array.
      # @param [Zif::Actions::Actionable] actionable
      def remove_actionable(actionable)
        @actionables.delete(actionable)
      end

      # Moves an {Zif::Actions::Actionable} to the start of the {actionables} array, so it is processed first
      # @param [Zif::Actions::Actionable] actionable
      def promote_actionable(actionable)
        @actionables.unshift(remove_actionable(actionable))
      end

      # Moves an {Zif::Actions::Actionable} to the end of the {actionables} array, so it is processed last
      # @param [Zif::Actions::Actionable] actionable
      def demote_actionable(actionable)
        @actionables.push(remove_actionable(actionable))
      end

      # ------------------
      # @!group 2. Private-ish methods

      # Iterate through {actionables} and invoke {Zif::Action::Actionable#perform_actions}
      # Unless you are doing something advanced, this should be invoked automatically by {Zif::Game#standard_tick}
      # @api private
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
end
