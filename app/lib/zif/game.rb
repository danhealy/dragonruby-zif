# Orchestrates main tick & active Scene
#
# Expects the @scene to respond to #perform_tick (Zif::Scene)
# If @scene.perform_tick returns an instance of Zif::Scene, the game will switch to that scene
# Otherwise you can pass a block to #standard_tick and do something with the @scene.perform_tick return value
#
# Suggested initialization procedure in main.rb:
#
# class MyGame < Zif::Game
#   def initialize
#     super()
#     MyOneTime.setups # do anything here, like register services...
#     register_scene(:rainbow_road, RainbowRoadScene) # (RainbowRoadScene is a Zif::Scene subclass)
#     @scene = OpeningScene.new # (this is a Zif::Scene subclass)
#   end
# end
#
# def tick(args)
#   if args.tick_count == 2
#     $game = MyGame.new
#     $game.scene.prepare_scene # if needed on first scene
#   end
#
#   $game&.perform_tick
# end
#
# ---
#
# Custom scene switching behavior:
#
#  # Important that this isn't named #tick, otherwise it gets suppressed by "trace!"
#  def perform_tick
#    standard_tick do |tick_result|
#      case tick_result
#      when :load_water_level
#        water_level = WaterLevelScene.new
#        water_level.do_special_stuff # like something you can't do in #prepare_scene for whatever reason
#        @scene = water_level
#      else # an unhan
#        @scene = OpeningScene.new
#      end
#    end
#  end

module Zif
  # Orchestrates main tick & active Scene
  class Game
    include Traceable
    attr_gtk
    attr_accessor :scene, :services, :action_service, :scene_registry

    # Suggested that you override this and set @scene
    def initialize
      $services = Zif::Services.new
      @services = $services
      @services.register(:action_service, Zif::ActionService.new)
      @tracer_service_name = :tracer
      @services.register(@tracer_service_name, Zif::TickTraceService.new)
      @services.register(:sprite_registry, Zif::SpriteRegistry.new)
      @services.register(:input_service, Zif::InputService.new)
      @scene_registry = {}
    end

    def register_scene(scene_name, scene)
      @scene_registry[scene_name] = scene
    end

    # Override and call super() if you need to pass a block to #standard_tick or do anything else
    def perform_tick
      standard_tick # No block provided usually
    end

    # This should not be overridden. Override #perform_tick instead
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

      @services[:action_service].run_all_actions
      mark('#standard_tick: end')
      @services[:tracer].finish
    rescue StandardError => e
      decorate_exception(e)
      @services[:tracer]&.finish
      $gtk.console
      $gtk.pause!
    end

    def switch_scene(tick_result)
      return tick_result if tick_result.is_a?(Zif::Scene)
      return tick_result.new if tick_result.is_a?(Class)

      return unless @scene_registry[tick_result] && @scene_registry[tick_result] <= Zif::Scene

      @scene_registry[tick_result].new
    end

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
      puts '=' + ('-' * 118) + '='
    end

    def serialize
      {
        scene:  @scene.class.to_s,
        tracer: @services[:tracer]&.last_label
      }
    end

    def inspect
      serialize.to_s
    end

    def to_s
      serialize.to_s
    end
  end
end
