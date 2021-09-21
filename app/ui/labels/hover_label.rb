module ExampleApp
  # Settings for the Kenney Future font
  class HoverLabel < Zif::UI::Label
    include Zif::Clickable
    include Zif::Hoverable

    FONT = 'sprites/kenney-uipack-space/Fonts/kenvector_future.ttf'.freeze

    COLOR = {
      r: 255,
      g: 255,
      b: 255,
      a: 255
    }.freeze

    HIGHLIGHT = {
      r: 51,
      g: 51,
      b: 255,
      a: 255
    }.freeze

    def initialize(
      text,
      size: -1,
      alignment: :left,
      r: COLOR[:r],
      g: COLOR[:g],
      b: COLOR[:b],
      a: COLOR[:a],
      blend: :alpha
    )
      super(text, size: size, alignment: alignment, font: FONT, r: r, g: g, b: b, a: a, blend: blend)

      @on_mouse_enter = lambda { |p|
        @r= HIGHLIGHT[:r]
        @g= HIGHLIGHT[:g]
        @b= HIGHLIGHT[:b]
        @a= HIGHLIGHT[:a]
      }

      @on_mouse_exit = lambda { |p|
        @r= COLOR[:r]
        @g= COLOR[:g]
        @b= COLOR[:b]
        @a= COLOR[:a]
      }
    end

    # Placeholder so Click wont crash for the label
    def clicked?(point, kind=:up)
      self
    end
  end
end
