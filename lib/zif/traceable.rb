module Zif
  # This mixin helps you wrap calling out to {Zif::Services::TickTraceService} by providing a local {mark} method.
  #
  # Messages logged using this {mark} method are automatically prefixed with the class name using {mark_prefix}
  # Additionally, it sets up an attribute {tracer_service_name} you can use to avoid having to dig into your +$services+
  # hash.  Therefore, the only requirement is that you set up the +$services+ global variable to be an instance of
  # {Zif::Services::ServiceGroup}.  This is done for you if you are using {Zif::Game}.
  module Traceable
    # @return [Symbol] The name of your {Zif::Services::TickTraceService} as registered in +$services+ ({Zif::Services::ServiceGroup})
    attr_accessor :tracer_service_name

    # @return [Zif::Services::TickTraceService] Returns your active instance of the {Zif::Services::TickTraceService}
    def tracer(service_name=@tracer_service_name)
      $services[service_name.to_sym]
    end

    # This marks a section of code you wish to add to your tick traces to {tracer}.
    # It adds the class name to your message via invoking {mark_prefix} for you.
    # @param [String] msg The message you wish to log for this section of code.
    def mark(msg='Oh Hi Mark')
      tracer&.mark("#{mark_prefix}#{msg}")
    end

    # Same as {mark} but also sends the output to +puts+ so it will appear in your console.
    # @param [String] msg The message you wish to log for this section of code.
    # @param [Integer] frequency The frequency at which you wish to print to console, every +1, 6, 60, or 600+ ticks
    def mark_and_print(msg='Oh Hi Mark', frequency: 1)
      full_msg = "#{mark_prefix}#{msg}"
      case frequency
      when 6
        puts6 full_msg
      when 60
        puts60 full_msg
      when 600
        puts600 full_msg
      else
        puts full_msg
      end
      mark(msg)
    end

    # ------------------
    # @!group 2. Private-ish methods

    # @return [String] "<class name>: "
    # @todo This only prints the class name, figure out some way of printing the name of the caller method
    # @api private
    def mark_prefix
      "#{self.class.name}: "
    end
  end
end
