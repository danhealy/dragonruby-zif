module Zif
  module Services
    # Register a group of {Zif::Services}.
    #
    # {Zif::Game} automatically saves an instance of this class at the +$services+ global variable, and registers the
    # typical services ({Zif::Services::InputService}, {Zif::Services::ActionService}...) on it for you.  It's also
    # accessible through the {Zif::Game} instance via {Zif::Game#services}.
    #
    # @example Invoke a method on the {Zif::Services::TickTraceService} via the ServiceGroup instance on a {Zif::Game}
    #   $game.services[:tracer].mark("Hello World")
    class ServiceGroup
      # @return [Array<Zif::Services>] The registered services.
      attr_reader :services

      def initialize
        @services = {}
      end

      # @param [Symbol] name The name of a service
      # @return [Zif::Services] A {Zif::Services} previously registered with +name+
      def [](name)
        @services[name]
      end

      # @param [Symbol] name The name of a service
      # @return [Zif::Services] A {Zif::Services} previously registered with +name+
      def named(name)
        @services[name]
      end

      # Register a service by name.
      # @param [Symbol] name The name of a service
      # @param [Zif::Services] new_service A {Zif::Services} instance to register at +name+
      def []=(name, new_service)
        @services[name] = new_service
      end

      # Register a service by name.
      # @param [Symbol] name The name of a service
      # @param [Zif::Services] new_service A {Zif::Services} instance to register at +name+
      def register(name, new_service)
        @services[name] = new_service
      end
    end
  end
end
