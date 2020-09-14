module Zif
  # A mixin to invoke #mark on a :tick_trace Service
  module Traceable
    attr_accessor :tracer_service_name

    def tracer(service_name=@tracer_service_name)
      $services[service_name]
    end

    # I wish I could print the name of the caller method here...
    def mark(msg='Mark')
      tracer&.mark("#{self.class.name}: #{msg}")
    end
  end
end
