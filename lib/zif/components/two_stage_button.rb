module Zif
  # Define a set of sprites for both the pressed state and the normal state
  # Use #toggle_pressed to switch states
  # Override the height methods to center the label
  # #resize and #redraw should occur in subclass initialize
  class TwoStageButton < ComplexSprite
    attr_accessor :normal, :pressed, :is_pressed, :label

    def initialize(target_name, &block)
      super(target_name)
      @normal = []
      @pressed = []
      @is_pressed = false
      @render_target.containing_sprite.on_mouse_up = lambda { |point|
        block.call(point) if block
        toggle_pressed if @is_pressed
      }
      @render_target.containing_sprite.on_mouse_changed = ->(point) { on_mouse_changed(point) }
      @render_target.containing_sprite.on_mouse_down = ->(_point) { toggle_pressed }
    end

    def pressed_height
      0
    end

    def normal_height
      0
    end

    def label_y_offset
      4
    end

    def label_y_pressed_offset
      6
    end

    def cur_height
      @is_pressed ? pressed_height : normal_height
    end

    def on_mouse_changed(point)
      toggle_pressed if point.inside_rect?(containing_sprite.rect) != @is_pressed
    end

    def toggle_pressed
      @is_pressed = !@is_pressed
      redraw
    end

    def redraw
      @render_target.sprites = @is_pressed ? @pressed : @normal
      if @label
        @render_target.labels = [@label.label_attrs.merge(
          {
            x: (width / 2).floor,
            y: ((pressed_height + @label.min_height) / 2) + label_y_offset - (@is_pressed ? label_y_pressed_offset : 0)
          }
        )]
      end
      draw_target
    end
  end
end
