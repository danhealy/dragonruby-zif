module Zif
  # Inspired by https://developer.apple.com/documentation/spritekit/skaction
  # and Squirrel Eiserloh's GDC talk on nonlinear transformations https://www.youtube.com/watch?v=mr5xkf6zSzk
  # A transition of a set of attributes over time using an easing function (aka tweening, easing)
  # Meant to be applied to an object using the Actionable mixin
  class Action
    include Zif::Serializable
    attr_accessor :start, :finish, :callback, :easing, :repeat, :duration, :started_at, :dirty, :rounding, :finish_early

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

    def initialize(node, finish, duration=1.second, easing=:linear, rounding=:round, repeat=1, &block)
      raise ArgumentError, "Invalid node: #{node}, expected a Zif::Actionable" unless node.is_a? Zif::Actionable

      @node = node

      unless EASING_FUNCS.include? easing
        raise ArgumentError, "Invalid easing function: '#{easing}'.  Must be in #{EASING_FUNCS}"
      end

      @easing = easing

      unless ROUNDING_FUNCS.include? rounding
        raise ArgumentError, "Invalid rounding function: '#{rounding}'.  Must be in #{ROUNDING_FUNCS}"
      end

      @rounding = rounding

      @start = {}
      finish.keys.each do |key|
        [key, "#{key}="].each do |req_meth|
          unless @node.respond_to?(req_meth)
            raise ArgumentError, "Invalid finish condition: #{@node} doesn't have '##{req_meth}'"
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

    def reset_start
      @finish.keys.each do |key|
        @start[key] = @node.send(key)
      end
    end

    def reset_duration
      @started_at = $gtk.args.tick_count - 1
    end

    def perform_tick
      @dirty = false
      @finish.each do |key, val|
        start = @node.send(key)
        # puts "  easing #{key} #{start} -> #{val}"
        if start.is_a? Numeric
          change_to = ease(@start[key], val)
          change_to = change_to.send(@rounding) unless @rounding == :none
        else
          change_to = val
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
      return @dirty
    end

    def progress
      @finish_early ? 1.0 : ($gtk.args.tick_count - @started_at).fdiv(@duration)
    end

    def finish_early!
      @finish_early = true
    end

    def iteration_complete?
      progress == 1.0
    end

    def ease(start_val, finish_val)
      ret = ((finish_val - start_val) * send(@easing)) + start_val
      # puts "Action#ease: #{start_val} -> #{@easing} (#{self.send(@easing)}) -> #{finish_val} = #{ret}"
      ret
    end

    def complete?
      # puts "Action#complete?: Action complete! #{self.inspect} #{@node.class}" if @repeat.zero?
      @repeat.zero?
    end

    def perform_callback
      # puts "Action#perform_callback: Callback triggered"
      @callback.call(self)
    end

    # ----------------
    # Easing Functions

    def immediate(_x)
      1.0
    end

    def linear(x=progress)
      x
    end

    def flip(x=progress)
      1 - x
    end

    def mix(a=:linear, b=:linear, rate=0.5, x=progress)
      (1 - rate) * send(a, x) + rate * send(b, x)
    end

    def crossfade(a=:linear, b=:linear, x=progress)
      mix(a, b, x, x)
    end

    # https://www.youtube.com/watch?v=mr5xkf6zSzk
    def smooth_start(x=progress)
      x * x
    end

    def smooth_start3(x=progress)
      x * x * x
    end

    def smooth_start4(x=progress)
      x * x * x * x * x
    end

    def smooth_start5(x=progress)
      x * x * x * x * x * x
    end

    def smooth_stop(x=progress)
      flip(smooth_start(flip(x)))
    end

    def smooth_stop3(x=progress)
      flip(smooth_start3(flip(x)))
    end

    def smooth_stop4(x=progress)
      flip(smooth_start4(flip(x)))
    end

    def smooth_stop5(x=progress)
      flip(smooth_start5(flip(x)))
    end

    def smooth_step(x=progress)
      crossfade(:smooth_start, :smooth_stop, x)
    end

    def smooth_step3(x=progress)
      crossfade(:smooth_start3, :smooth_stop3, x)
    end

    def smooth_step4(x=progress)
      crossfade(:smooth_start4, :smooth_stop4, x)
    end

    def smooth_step5(x=progress)
      crossfade(:smooth_start5, :smooth_stop5, x)
    end
  end
end
