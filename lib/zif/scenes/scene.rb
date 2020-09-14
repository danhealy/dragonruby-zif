module Zif
  # A Scene is a full-screen view of your game. The concept is to show one scene at a time.
  # So each scene in your game should be a subclass of Zif::Scene which overrides #perform_tick.
  # Using the structure in Zif::Game, #perform_tick comes after input handling and before updating Actionables.
  # So your subclass should use #perform_tick to add/remove Clickables/Actionables, and respond to any detected input.
  # Switching scenes is handled in Zif::Game, based on the return value of #perform_tick.
  class Scene
    include Zif::Serializable

    # This needs to be overridden
    def perform_tick
      raise "Zif::Scene#perform_tick: Please override #perform_tick for #{self.class}"
    end

    def prepare_scene
      # Optional - register sprites with input service, etc.
    end

    def unload_scene
      # Optional - reset input service clickables, etc
    end
  end
end
