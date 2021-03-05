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
  # @example An example scene:
  #   class OpeningScene < Zif::Scene
  #     def initialize
  #       # If OpeningScene is registered by symbol using Zif::Game#register_scene, this initialize will happen each
  #       # time the game switches to this scene.  Otherwise you could instantiate this scene somewhere and simply
  #       # return it from another scene's #perform_tick
  #       @dragon = Zif::Sprite.new # ....
  #       @hello = Zif::UI::Label.new("Hello World!").tap do |label|
  #         label.x = 100
  #         label.y = 100
  #       end
  #       @current_scene_tick_count = 0
  #     end
  #
  #     def prepare_scene
  #       # You probably want to remove the things registered with the services when scenes change
  #       # You can remove items explicitly using #remove_.., but #reset_.. will clear everything
  #       # You can also do this when a scene is being changed away from, using the #unload_scene method.
  #       $game.services[:action_service].reset_actionables
  #       $game.services[:input_service].reset
  #       $gtk.args.outputs.static_sprites.clear
  #       $gtk.args.outputs.static_labels.clear
  #
  #       # Now you can use this to do one-time setup code.
  #       $game.services[:action_service].register_actionable(@dragon)
  #       $game.services[:input_service].register_clickable(@dragon)
  #
  #       # Best practice is to use static outputs, this gives you a lot more performance and there is no need to append
  #       # to the array inside #perform_tick.
  #       # The only downside is that you have to manage this list manually.  You can remove sprites at any time in
  #       # #perform_tick.
  #       $gtk.args.outputs.static_sprites << @dragon
  #       $gtk.args.outputs.static_labels << @hello
  #     end
  #
  #     def perform_tick
  #       @current_scene_tick_count += 1
  #       @hello.text = "Hello World! #{@current_scene_tick_count}"
  #
  #       # Tell Zif::Game to attempt to switch to the scene registered with the name :rainbow_road after some time
  #       return :rainbow_road if @current_scene_tick_count > 200
  #     end
  #   end
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
