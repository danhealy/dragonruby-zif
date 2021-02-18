module Zif
  module Clickable
    attr_accessor :on_mouse_down, :on_mouse_up, :on_mouse_changed

    def absorb_click?
      on_mouse_up || on_mouse_down || on_mouse_changed
    end

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
