module Zif
  # The main entrypoint for your game.
  #
  # Orchestrates main tick & active {Zif::Scene}.
  #
  # It's suggested to subclass this so that you can set the opening scene during {initialize}, see example below.
  #
  # Includes +attr_gtk+ -- supports what DRGTK provides for these classes in addition to what is documented here.
  # http://docs.dragonruby.org/#----attr_gtk.rb
  #
  # Expects the {scene} to be an object which responds to +#perform_tick+ (See {Zif::Scene#perform_tick})
  # If +@scene.perform_tick+ returns an instance of {Zif::Scene}, the game will switch to that scene
  #
  # If you need some more advanced usage, you can override {perform_tick} to pass a block to {standard_tick} and do
  # something with the +@scene.perform_tick+ return value (See second example).
  #
  # @example Suggested initialization procedure:
  #
  #   # =-=-=- In your app/my_game.rb -=-=-=
  #   class MyGame < Zif::Game
  #     def initialize
  #       super()
  #       MyOneTime.setups # do anything here, like register services...
  #       register_scene(:rainbow_road, RainbowRoadScene) # (RainbowRoadScene is a Zif::Scene subclass)
  #       @scene = OpeningScene.new # (this is a Zif::Scene subclass)
  #     end
  #   end
  #
  #   # =-=-=- In your app/main.rb -=-=-=
  #   # Require all of the Zif library:
  #   require 'app/lib/zif/require.rb'
  #   require 'my_game.rb'
  #
  #   def tick(args)
  #     if args.tick_count == 2
  #       $game = MyGame.new
  #       $game.scene.prepare_scene # if needed on first scene
  #     end
  #
  #     $game&.perform_tick
  #   end
  #
  # @example Custom scene switching behavior (advanced):
  #
  #    # =-=-=- In your MyGame class in app/my_game.rb -=-=-=
  #    # You would only need to override #perform_tick if you are doing something advanced.  Generally you can just
  #    # use the normal scene switching mechanisms described in the example above.
  #    #
  #    # Important that this isn't named #tick, otherwise it gets suppressed by "trace!"
  #    def perform_tick
  #      # tick_result here is just the return value of the active scene's #perform_tick method
  #      standard_tick do |tick_result|
  #        case tick_result
  #        when :load_water_level
  #          water_level = WaterLevelScene.new
  #          water_level.do_special_stuff # like something you can't do in #prepare_scene for whatever reason
  #          @scene = water_level
  #        else # an unhandled return
  #          @scene = OpeningScene.new
  #        end
  #      end
  #    end
  class Game
    include Traceable
    attr_gtk

    # @return [Zif::Scene] The active scene
    attr_accessor :scene

    # @return [Zif::Services::ServiceGroup] A handle for all services.
    attr_accessor :services

    # @return [Hash<Symbol, Class<Zif::Scene>>] A mapping of scene names to classes.  Use {register_scene} to add one.
    attr_reader :scene_registry

    # ------------------
    # @!group 1. Public Interface

    # It's suggested that you extend this and set {scene} manually, see the example above.
    def initialize
      $services = Zif::Services::ServiceGroup.new
      @services = $services
      @services.register(:action_service, Zif::Services::ActionService.new)
      @tracer_service_name = :tracer
      @services.register(@tracer_service_name, Zif::Services::TickTraceService.new)
      @services.register(:sprite_registry, Zif::Services::SpriteRegistry.new)
      @services.register(:input_service, Zif::Services::InputService.new)
      @scene_registry = {}
      @pause_actions = false

      Zif.check_compatibility
    end

    # Register a {Zif::Scene} subclass by a Symbol name, for scene transitions.
    # @param [Symbol] scene_name
    #   The name of the scene to register.  If your scene returns this symbol from {Zif::Scene#perform_tick}, this
    #   class will switch to this scene during {standard_tick}
    # @param [Class<Zif::Scene>] scene
    #   The class name of a {Zif::Scene} subclass.  When invoked via the +scene_name+, a new instance of this class is
    #   created and switched to be the active scene.
    def register_scene(scene_name, scene)
      @scene_registry[scene_name] = scene
    end

    # Override, or extend with +super()+ if you need to pass a block to {standard_tick} or do anything else
    def perform_tick
      standard_tick # No block provided usually
    end

    # @see Zif::Serializable
    def serialize
      {
        scene:  @scene.class.to_s,
        tracer: @services[:tracer]&.last_label
      }
    end

    # @see Zif::Serializable
    def inspect
      serialize.to_s
    end

    # @see Zif::Serializable
    def to_s
      serialize.to_s
    end

    # ------------------
    # @!group 2. Private-ish methods

    # Generally this shouldn't be called directly, unless you are extending {perform_tick}.  See example above.
    # @param [Proc] _block A block to run which is given the return value of the active {scene}'s +#perform_tick+ method
    def standard_tick(&_block)
      @services[:tracer].reset_tick
      mark('#standard_tick: begin')

      @services[:input_service].process_click
      mark('#standard_tick: input_service #process_click')

      tick_result = @scene.perform_tick
      mark('#standard_tick: Scene #perform_tick complete')

      next_scene = switch_scene(tick_result)
      if next_scene
        next_scene.prepare_scene
        @scene = next_scene
      else
        yield tick_result if block_given?
      end

      mark('#standard_tick: Scene switching handled')

      mark('#standard_tick: Action service complete') if @services[:action_service].run_all_actions
      mark('#standard_tick: Complete')
      @services[:tracer].finish
    rescue StandardError => e
      decorate_exception(e)
      @services[:tracer]&.finish
      $gtk.console
      $gtk.pause!
    end

    # @return [Zif::Scene] An instance of a {Zif::Scene} to transition to.
    # @api private
    def switch_scene(tick_result)
      return tick_result if tick_result.is_a?(Zif::Scene)
      return tick_result.new if tick_result.is_a?(Class)

      return unless @scene_registry[tick_result] && @scene_registry[tick_result] <= Zif::Scene

      @scene_registry[tick_result].new
    end

    # @api private
    def decorate_exception(e)
      puts '=' * 120
      puts "Exception: #{e.class}"
      puts e.message.wrap(118).gsub("\n", "\n  ")
      tick_trace_step = @services[:tracer]&.last_label
      if tick_trace_step
        puts "Exception occurred after: #{tick_trace_step}"
      else
        puts 'Exception occured before tracer service was initialized'
      end
      puts "=#{'-' * 118}="
    end
  end
end
