module ExampleApp
  # Just some shared functionality across all Zif example app scenes.
  class ZifExampleScene < Zif::Scene
    include Zif::Traceable

    attr_accessor :tracer_service_name, :scene_timer, :next_scene

    def initialize
      @tracer_service_name = :tracer
      @scene_timer = 60 * 60
      @pause_timer = false
      @timer_bar = Zif::Sprite.new
      @timer_bar.assign(
        x:       0,
        y:       718,
        w:       1280,
        h:       2,
        a:       80,
        z_index: 999,
        path:    'sprites/white_1.png'
      )
      @timer_bar_set = false
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
      @timer_bar_set = false
    end

    def perform_tick
      $game.services[:tracer].clear_averages if $gtk.args.inputs.keyboard.key_up.delete

      if $gtk.args.inputs.keyboard.key_up.pageup
        @pause_timer = !@pause_timer
        @scene_timer += 100 if @pause_timer
      end

      @scene_timer -= 1 unless @pause_timer

      display_timer_bar

      display_context_labels

      return unless @next_scene

      return @next_scene if @force_next_scene || $gtk.args.inputs.keyboard.key_up.pagedown || !@scene_timer.positive?
    end

    def display_timer_bar
      unless @timer_bar_set
        $gtk.args.outputs.static_sprites << @timer_bar
        @timer_bar_set = true
      end

      if @pause_timer
        @timer_bar.assign(
          w: 1280,
          r: 255,
          g: 0,
          b: 0
        )
      else
        @timer_bar.assign(
          w: @scene_timer,
          r: 0,
          g: 255,
          b: 180
        )
      end
    end

    # rubocop:disable Layout/LineLength
    def display_context_labels
      color = {r: 255, g: 255, b: 255, a: 255}
      wait_text = @pause_timer ? '. Paused, press pgup to unpause.' : ", or wait #{@scene_timer} ticks.  Press pgup to pause."
      $gtk.args.outputs.labels << { x: 4, y: 720 - 2, text: "#{self.class.name}.  Press pgdown to #{@next_scene}#{wait_text}" }.merge(color)
      $gtk.args.outputs.labels << { x: 0, y: 720 - 22, text: "#{tracer&.last_tick_ms} #{$gtk.args.gtk.current_framerate}fps" }.merge(color)
      $gtk.args.outputs.labels << { x: 4, y: 24, text: "Last slowest mark: #{tracer&.slowest_mark}" }.merge(color)
      $gtk.args.outputs.labels << { x: 4, y: 44, text: "Max slowest mark: #{tracer&.slowest_max_mark}" }.merge(color)
      $gtk.args.outputs.labels << { x: 4, y: 64, text: "Avg slowest mark: #{tracer&.slowest_avg_mark}" }.merge(color)
    end
    # rubocop:enable Layout/LineLength
  end
end
