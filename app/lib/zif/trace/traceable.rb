module Zif
  # A mixin to invoke #mark on a :tick_trace Service
  module Traceable
    attr_accessor :tracer_service_name

    def tracer(service_name=@tracer_service_name)
      $services[service_name.to_sym]
    end

    # I wish I could print the name of the caller method here...
    def mark(msg='Mark')
      tracer&.mark("#{mark_prefix}#{msg}")
    end

    def mark_and_print(msg='Mark')
      puts "#{mark_prefix}#{msg}"
      mark(msg)
    end

    def mark_prefix
      "#{self.class.name}: "
    end
  end
end
