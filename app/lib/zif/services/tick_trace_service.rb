module Zif
  module Services
    # This service is for performance tuning your game.
    #
    # It is set up and torn down for you if you use Zif::Game
    # The idea is that you
    # - {reset_tick} in the beginning of your tick, then
    # - include {Zif::Traceable} and then use {mark} to timestamp important areas in your code during a tick,
    #     (e.g. mark("#my_method: Just did something!") )
    # - and finally {finish} the tick
    #
    # If your tick takes longer than {time_threshold}, it will report the full trace info and highlight the section
    # which took the most time to execute.  The game will begin to dip below 60fps if your tick takes longer than about
    # 16ms, but the default threshold is 20ms so it should only notify you if something is really off.
    #
    # Turn on running average calculation by setting {measure_averages} to +true+
    class TickTraceService
      # @return [Float] Time, in seconds.  A trace report is generated if your tick takes longer than this amount.
      attr_accessor :time_threshold

      # @return [String] A string label for the slowest measured {mark}ed section of code.
      attr_reader :slowest_mark

      # @return [String] The amount of time the last tick took, in milliseconds, as a string
      attr_reader :last_tick_ms

      # @return [Boolean] Should the service report average times?  This is somewhat computationally expensive.
      attr_accessor :measure_averages

      # @return [Hash] A data structure used to save min/max/avg times for each marked section of code.
      attr_reader :averages

      # @return [String] The amount of time the average slowest marked section of code takes every tick, in ms
      attr_accessor :slowest_avg_mark

      # @return [String] The amount of time the slowest marked section of code ever seen took, in ms
      attr_accessor :slowest_max_mark

      # ------------------
      # @!group 1. Public Interface

      # @param [Float] time_threshold {time_threshold}
      # @param [Boolean] measure_averages {measure_averages}
      def initialize(time_threshold: 0.02, measure_averages: false)
        @time_threshold = time_threshold
        @measure_averages = measure_averages
        @enabled = true
        clear_averages
        reset_tick
      end

      # Turns on the TickTrace analysis
      def enable!
        @enabled = true
      end

      # Turns off the TickTrace analysis
      def disable!
        @enabled = false
      end

      # @return [Boolean] Is TickTrace turned on?
      def enabled?
        @enabled
      end

      # Resets the time measurement for this tick, typically used at the beginning of your tick.
      def reset_tick
        @times = []
        @start_time = Time.now
        @last_time = @start_time
      end

      # Resets the data saved for average time spent in your marked sections of code.
      # Calculating averages is computationally expensive based on the number of unique marked sections of code that
      # have been measured, so clearing the averages is a good idea if you have built up too many unique sections.
      def clear_averages
        @averages = Hash.new do |h, k|
          h[k] = {
            min:   Float::INFINITY,
            max:   -Float::INFINITY,
            avg:   nil,
            count: 0
          }
        end
      end

      # Invoke this method to tell the TickTraceService that a section of code has completed.
      # Time is measured between marked sections.
      # @param [String] label The name of the section of code prior to this call.  Used in reporting
      def mark(label)
        return unless enabled?

        t = Time.now
        delta = t - @last_time
        @times << {
          label:   label,
          delta:   delta,
          elapsed: t - @start_time
        }
        @last_time = t

        return unless @measure_averages

        @averages[label][:min] = [@averages[label][:min], delta].min
        @averages[label][:max] = [@averages[label][:max], delta].max

        if @averages[label][:avg]
          @averages[label][:avg] =
            ((@averages[label][:avg] * @averages[label][:count]) + delta).fdiv(@averages[label][:count] + 1)

        else
          @averages[label][:avg] = delta
        end

        @averages[label][:count] += 1
      end

      # This is used to extract the name of the last {mark}-ed code.
      # Useful for exception messages.
      def last_label
        @times&.last&.dig(:label)
      end

      # ------------------
      # @!group 2. Private-ish methods

      # You only need to call this method directly if you are using this service without {Zif::Game}.
      # Tells the TickTraceService that the tick is complete and it should finish analysis for this tick.
      # If your tick has taken longer than {time_threshold}, a report is generated.
      # @api private
      def finish
        return unless enabled?

        elapsed = @last_time - @start_time
        @last_tick_ms = format_ms(elapsed)

        if @measure_averages
          avg_culprit, avg_culprit_time = @averages.max_by { |_label, time| time[:avg] }
          @slowest_avg_mark = "'#{avg_culprit}' #{format_ms(avg_culprit_time[:avg])}"
          max_culprit, max_culprit_time = @averages.max_by { |_label, time| time[:max] }
          @slowest_max_mark = "'#{max_culprit}' #{format_ms(max_culprit_time[:max])}"
        end

        over_threshold = (elapsed > @time_threshold)
        return unless over_threshold

        culprit = @times.max_by { |time| time[:delta] }
        @slowest_mark = "'#{culprit[:label]}' #{format_ms(culprit[:delta])}"

        tick_details = "#{@last_tick_ms} elapsed > #{format_ms(@time_threshold)} threshold, "
        tick_details += "longest step #{@slowest_mark}"
        puts '=' * 80
        puts "Zif::Services::TickTraceService: Slow tick. #{tick_details}:"
        print_times
      end

      # Prints the time elapsed for each marked section of code in this tick.
      # @api private
      def print_times(indented=2)
        indent = ' ' * indented
        puts "#{indent}#{'%9s' % 'mark'} #{'%9s' % 'delta'} label"
        @times.each do |time|
          puts "#{' ' * indented}#{format_ms(time[:elapsed])} #{format_ms(time[:delta])} #{time[:label]}"
        end
      end

      # There's gotta be a better way to do this..
      # ...all because '%3.3f' % 0.12 will print '0.120' instead of '  0.120'
      # @api private
      def format_ms(in_seconds)
        ms = in_seconds * 1000.0
        whole_ms = ms.floor
        dec = ms - whole_ms
        "#{'%3d' % whole_ms}#{('%.3f' % dec).gsub('0.', '.')}ms"
      end
    end
  end
end
