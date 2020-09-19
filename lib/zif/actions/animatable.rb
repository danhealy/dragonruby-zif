module Zif
  # A mixin for an Actionable class which can set `#path=`
  module Animatable
    attr_accessor :animation_sequences, :cur_animation

    # Creates an animation sequence based on an array of [[:path_name, ticks_to_hold]]
    def new_basic_animation(seq_name, paths_and_durations, repeat=:forever, &block)
      actions = paths_and_durations.map do |(path, duration)|
        new_action({path: "sprites/#{path}.png"}, duration, :immediate, :none)
      end
      register_animation_sequence(seq_name, Sequence.new(actions, repeat, &block))
    end

    def register_animation_sequence(seq_name, sequence)
      @animation_sequences ||= {}
      @animation_sequences[seq_name] = sequence
    end

    def run_animation_sequence(seq_name)
      raise ArgumentError, "No animation sequence named '#{seq_name}' registered" unless @animation_sequences[seq_name]

      # puts "Running animation sequence #{seq_name} #{@animation_sequences[seq_name].inspect}"
      stop_animating

      @cur_animation = seq_name
      @animation_sequences[@cur_animation].cur_action.reset_duration

      run(@animation_sequences[@cur_animation])
    end

    def stop_animating
      return unless @cur_animation && @animation_sequences && @animation_sequences[@cur_animation]
      stop_action(@animation_sequences[@cur_animation])
    end
  end
end
