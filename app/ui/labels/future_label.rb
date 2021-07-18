module ExampleApp
  # Settings for the Kenney Future font
  class FutureLabel < Zif::UI::Label
    include Zif::Serializable

    FONT = 'sprites/kenney-uipack-space/Fonts/kenvector_future.ttf'.freeze

    COLOR = {
      r: 51,
      g: 51,
      b: 51,
      a: 255
    }.freeze

    def initialize(text, size: -1, alignment: :left, r: COLOR[:r], g: COLOR[:g], b: COLOR[:b], a: COLOR[:a], blend: :alpha)
      super(text, size: size, alignment: alignment, font: FONT, r: r, g: g, b: b, a: a, blend: blend)
    end
  end
end
