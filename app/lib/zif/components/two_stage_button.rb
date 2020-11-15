module Zif
  # Define a set of sprites for both the pressed state and the normal state
  # Use #toggle_pressed to switch states
  #
  # label_y_offset and pressed_height are for adjusting the height of the label when recentering.
  # Offset always applied, pressed_height used instead of @h if pressed
  class TwoStageButton < CompoundSprite
    attr_accessor :normal, :pressed, :is_pressed,
                  :label_y_offset, :pressed_height

    def initialize(name=Zif.random_name('two_stage_button'), &block)
      super(name)
      @normal = []
      @pressed = []
      @is_pressed = false
      @on_mouse_up = lambda { |_sprite, point|
        block&.call(point)
        toggle_pressed if @is_pressed
      }
      @on_mouse_changed = ->(_sprite, point) { toggle_on_change(point) }
      @on_mouse_down = ->(_sprite, _point) { toggle_pressed }
      @label_y_offset = 0
    end

    def toggle_on_change(point)
      toggle_pressed if point.inside_rect?(rect) != @is_pressed
    end

    def press
      @is_pressed = true
      recenter_label
      @sprites = @pressed
    end

    def unpress
      @is_pressed = false
      recenter_label
      @sprites = @normal
    end

    def toggle_pressed
      if @is_pressed
        unpress
      else
        press
      end
    end

    def label
      @labels.first
    end

    def recenter_label
      return unless label

      cur_h = @is_pressed ? (@pressed_height || @h) : @h
      label.recenter_in(@w, cur_h, @label_y_offset)
    end

    def retruncate_label(padding=0)
      return unless label

      label.retruncate(@w - padding)
    end

    def label_text=(text)
      return unless label

      label.text = text
      retruncate_label
    end
  end
end
