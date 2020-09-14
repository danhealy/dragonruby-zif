module Zif
  # Designed for global functionality
  # You could initialize as $services, or if you are using $game you can set it as an ivar: $game.services
  # Example:
  # $game.services[:tracer].mark("Hello")
  class Services
    def initialize
      @services = {}
    end

    def [](name)
      @services[name]
    end

    def named(name)
      @services[name]
    end

    def []=(name, new_service)
      @services[name] = new_service
    end

    def register(name, new_service)
      @services[name] = new_service
    end
  end
end
