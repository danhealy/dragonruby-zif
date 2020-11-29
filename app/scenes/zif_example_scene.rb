# Just some shared functionality across all Zif example app scenes.
class ZifExampleScene < Zif::Scene
  include Zif::Traceable

  attr_accessor :tracer_service_name, :scene_timer, :next_scene

  def initialize
    @tracer_service_name = :tracer
    @scene_timer = 60 * 60
    @pause_timer = false
  end

  def prepare_scene
    # You probably want to remove the things registered with the services when scenes change
    # You can remove items explicitly using #remove_.., but #reset_.. will clear everything
    # You can also do this when a scene is being changed away from, using the #unload_scene method.
    $game.services[:action_service].reset_actionables
    $game.services[:input_service].reset
    tracer.clear_averages
    $gtk.args.outputs.static_sprites.clear
    $gtk.args.outputs.static_labels.clear
  end

  def perform_tick
    display_context_labels

    $game.services[:tracer].clear_averages if $gtk.args.inputs.keyboard.key_up.delete

    if $gtk.args.inputs.keyboard.key_up.pageup
      @pause_timer = !@pause_timer
      @scene_timer += 100 if @pause_timer
    end

    @scene_timer -= 1 unless @pause_timer

    return unless @next_scene

    return @next_scene if @force_next_scene || $gtk.args.inputs.keyboard.key_up.space || !@scene_timer.positive?
  end

  # rubocop:disable Layout/LineLength
  def display_context_labels
    color = {r: 255, g: 255, b: 255, a: 255}
    $gtk.args.outputs.labels << { x: 4, y: 720 - 0, text: "#{self.class.name}.  Press spacebar to transition to #{@next_scene}, or wait #{@scene_timer} ticks." }.merge(color)
    $gtk.args.outputs.labels << { x: 0, y: 720 - 20, text: "#{tracer&.last_tick_ms} #{$gtk.args.gtk.current_framerate}fps" }.merge(color)
    $gtk.args.outputs.labels << { x: 4, y: 24, text: "Last slowest mark: #{tracer&.slowest_mark}" }.merge(color)
    $gtk.args.outputs.labels << { x: 4, y: 44, text: "Max slowest mark: #{tracer&.slowest_max_mark}" }.merge(color)
    $gtk.args.outputs.labels << { x: 4, y: 64, text: "Avg slowest mark: #{tracer&.slowest_avg_mark}" }.merge(color)
  end
  # rubocop:enable Layout/LineLength
end
