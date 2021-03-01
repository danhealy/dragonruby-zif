module Zif
  # A Scene is a full-screen view of your game. The concept is to show one scene at a time.
  #
  # Each scene in your game should be a subclass of {Zif::Scene} which overrides at least {#perform_tick}.
  #
  # Using the structure in {Zif::Game}, {#perform_tick} comes after input handling and before updating
  # {Actions::Actionable}s.
  #
  # Your subclass should use {#perform_tick} to add/remove {Clickable}s/{Actions::Actionable}s, and respond to any
  # detected input. {#prepare_scene} and {#unload_scene} will be called before and after scene transition.
  #
  # Switching scenes is handled in {Zif::Game}, based on the return value of {#perform_tick}.
  #
  # @abstract Subclass and override at least {#perform_tick}.
  #
  # @todo Add a simple example
  #
  # @see Zif::Game#standard_tick
  class Scene
    include Zif::Serializable

    # Your Scene subclass must override this method.
    #
    # @see Zif::Game#register_scene
    # @return [Symbol, Zif::Scene, nil] Direction to {Zif::Game} about scene transition.
    #
    #   +nil+ if we are staying on this scene
    #
    #   +Symbol+ if one has been registered using {Zif::Game#register_scene}
    #
    #   +Zif::Scene+ subclass instance to transition directly
    def perform_tick
      raise "Zif::Scene#perform_tick: Please override #perform_tick for #{self.class}"
    end


    # Optional - Your scene can use this for setup code before the scene is displayed.
    # You could register sprites with input service, etc.
    # @return [void] N/A - Ignored by {Zif::Game}
    def prepare_scene
    end

    # Optional - Your scene can use this for tear-down code when the scene is being transitioned away.
    # You could reset input service clickables, etc
    # @return [void] N/A - Ignored by {Zif::Game}
    def unload_scene
    end
  end
end
