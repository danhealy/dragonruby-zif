module Zif
  module UI
    # This is a button which has pressed and unpressed states defined using two different sprites.
    #
    # If you give it a label by +mybutton.labels << Zif::Label.new ...+, there are some convenience methods available
    # {retruncate_label} {recenter_label} {label_text=}.
    #
    # It is able to have multiple sprites and a label because it inherits from {Zif::CompoundSprite}.
    #
    # Because this inherits from {Zif::CompoundSprite} and {Zif::Sprite}, it obtains a lot of extra functionality.
    # An important aspect is that it is a {Zif::Clickable} and can be registered as a clickable with the
    # {Zif::Services::InputService}
    #
    # Use {toggle_pressed} to switch states
    class TwoStageButton < CompoundSprite
      # @return [Zif::Sprite] The sprite to use for the normal (unpressed) state
      attr_accessor :normal
      # @return [Zif::Sprite] The sprite to use for the pressed state
      attr_accessor :pressed
      # @return [Boolean] Is the button in the pressed state?
      attr_accessor :is_pressed
      # @return [Integer] A Y offset to subtract from the label in the pressed state
      attr_accessor :label_y_offset
      # @return [Integer] The height of the pressed state sprite, used to calculate center for label
      attr_accessor :pressed_height

      # @param [String] name The name of the button, used for debugging
      # @param [Proc] block A block to execute when the button is pressed ({Zif::Clickable#on_mouse_up})
      def initialize(name=Zif.unique_name('two_stage_button'), &block)
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

      # Toggles pressed state if the point is inside the button.
      # @param [Array<Integer>] point +[x, y]+ point
      def toggle_on_change(point)
        toggle_pressed if point.inside_rect?(self) != @is_pressed
      end

      # Sets the button to the pressed state
      def press
        @is_pressed = true
        recenter_label
        @sprites = @pressed
      end

      # Sets the button to the unpressed state
      def unpress
        @is_pressed = false
        recenter_label
        @sprites = @normal
      end

      # Switches the pressed state
      def toggle_pressed
        if @is_pressed
          unpress
        else
          press
        end
      end

      # @return [Zif::Label] The label of the button
      def label
        @labels.first
      end

      # Moves the label to the center of the button
      # Applies the {label_y_offset} and {pressed_height}
      def recenter_label
        return unless label

        cur_h = @is_pressed ? (@pressed_height || @h) : @h
        label.recenter_in(@w, cur_h, offset: @label_y_offset)
      end

      # Calls {Zif::Label#retruncate} on the label
      # @param [Integer] padding Some padding to subtract from the width of the sprite
      def retruncate_label(padding=0)
        return unless label

        label.retruncate(@w - padding)
      end

      # Changes the {Zif::Label#full_text} of the label
      def label_text=(text)
        return unless label

        label.full_text = text
        retruncate_label
      end
    end
  end
end
