module Zif
  # A mixin to allow compatibility with {Zif::Services::InputService}
  #
  # Set click handler attributes {on_mouse_up}, {on_mouse_down}, {on_mouse_changed} to Lambdas accepting a +point+
  # argument to do something with this object when clicked.
  #
  # This also works for simple single touch responses on mobile targets.
  module Clickable

    # @return [Lambda] Called when the mouse click begins.  Called with +point+ [x, y] position Array arg.
    attr_accessor :on_mouse_down

    # @return [Lambda] Called when the mouse click ends.  Called with +point+ [x, y] position Array arg.
    attr_accessor :on_mouse_up

    # @return [Lambda] Called when the mouse moves while click is down.  Called with +point+ [x, y] position Array arg.
    attr_accessor :on_mouse_changed

    # The return value of this method informs {Zif::Services::InputService#process_click} that it should stop checking
    # subsequent eligible clickables for a response.
    # Imagine two overlapping clickables, if you want the one underneath this one to respond to a click, this should
    # return false.  If you only want the top clickable to respond, this should return true.
    # The default behavior is that it returns true if any standard click handlers are defined ({on_mouse_up},
    # {on_mouse_down}, {on_mouse_changed}).  To customize this behavior, override this method in your class.
    # @return [Boolean] Should clicks propagate through this object?
    def absorb_click?
      on_mouse_up || on_mouse_down || on_mouse_changed
    end

    # @param [Array<Integer>] point +[x, y]+ position Array of the current mouse click.
    # @param [Symbol] kind The kind of click coming through, one of +[:up, :down, :changed]+
    # @return [Object, nil]
    #   If the click is within the rectangle of this object, return this object.
    #   Otherwise return +nil+.
    def clicked?(point, kind=:up)
      # puts "Clickable:#{@name}: clicked? #{kind} #{kind.class} #{point} -> #{rect} = #{point.inside_rect?(self)}"
      return nil if (kind == :down) && !point.inside_rect?(self)

      click_handler = case kind
                      when :up
                        on_mouse_up
                      when :down
                        on_mouse_down
                      when :changed
                        on_mouse_changed
                      end

      # puts "Clickable:#{@name}: click handler: #{kind} #{click_handler}"

      click_handler&.call(self, point)
      self
    end
  end
end
