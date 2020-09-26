module Zif
  # Zif::TickTrace is for performance tracing in your game.  It is set up and torn down for you if you use Zif::Game
  # The idea is that you
  # - #reset_tick in the beginning of your tick, then
  # - include Zif::Traceable and then use #mark to timestamp important areas in your code during a tick,
  #     (e.g. mark("#my_method: Just did something!") )
  # - and finally #finish the tick
  #
  # If your tick takes longer than the time threshold, it will report the full trace info and highlight the section
  # which took the most time to execute.  The game will begin to dip below 60fps if your tick takes longer than about
  # 16ms, but the default threshold is 20ms so it should only notify you if something is really off.
  class TickTraceService
    # 0.02 cooresponds to 20ms
    def initialize(time_threshold=0.02)
      @time_threshold = time_threshold
      @enabled = true
      reset_tick
    end

    def enable!
      @enabled = true
    end
    
    def disable!
      @enabled = false
    end

    def enabled?
      @enabled
    end

    def reset_tick
      @times = []
      @start_time = Time.now
      @last_time = @start_time
    end

    def mark(label)
      return unless enabled?

      t = Time.now
      @times << {
        label:   label,
        delta:   t - @last_time,
        elapsed: t - @start_time
      }
      @last_time = t
    end

    def finish
      elapsed = @last_time - @start_time
      return unless elapsed > @time_threshold

      culprit = @times.max_by { |time| time[:delta] }

      tick_details = "#{format_ms(elapsed)} elapsed > #{format_ms(@time_threshold)} threshold, "
      tick_details += "longest step '#{culprit[:label]}' #{format_ms(culprit[:delta])}"
      puts '=' * 80
      puts "Zif::TickTraceService: Slow tick. #{tick_details}:"
      print_times
    end

    def print_times(indented=2)
      indent = ' ' * indented
      puts "#{indent}#{'%9s' % 'mark'} #{'%9s' % 'delta'} label"
      @times.each do |time|
        puts "#{' ' * indented}#{format_ms(time[:elapsed])} #{format_ms(time[:delta])} #{time[:label]}"
      end
    end

    # This is used to extract the name of the last #mark-ed code, useful for exception messages since we don't have
    # line numbers.
    def last_label
      # @times.map { |time| time&.dig(:label) }.join(" - ")
      @times&.last&.dig(:label)
    end

    # There's gotta be a better way to do this..
    # ...all because '%3.3f' % 0.12 will print '0.120' instead of '  0.120'
    def format_ms(in_seconds)
      ms = in_seconds * 1000.0
      whole_ms = ms.floor
      dec = ms - whole_ms
      "#{'%3d' % whole_ms}#{('%.3f' % dec).gsub('0.', '.')}ms"
    end
  end
end
