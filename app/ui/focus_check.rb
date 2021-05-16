module ExampleApp
  # This is an invisible sprite which overlays the entire screen, to manage input focus
  class FocusCheck < Zif::Sprite
    def initialize
      super(Zif.unique_name('focus_check'))
      @a = 0
      @w = 1280
      @h = 720
    end

    def absorb_click?
      false
    end
  end
end
