module Zif
  # A mixin to allow compatibility with {Zif::Services::InputService}
  #
  module Hoverable
    attr_accessor :hover_rect
    attr_accessor :on_mouse_enter
    attr_accessor :on_mouse_exit

    #   If the mouse first enters or leaves the rectangle of the object, return this object.
    #   Otherwise return +nil+.
    def hovered?(point)
      @hover_over ||=false
      inside = point.inside_rect?(@hover_rect)
      if (inside != @hover_over)
        # If this is the first time the mouse is inside the rectangle
        # or if this is the first time that the mouse has left the rectangle
        if (@hover_over)
          hover_handler = on_mouse_exit
          @hover_over = false
        else
          hover_handler = on_mouse_enter
          @hover_over = true
        end

        hover_handler&.call(point)
        self
      end
    end
  end
end
