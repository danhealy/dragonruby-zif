module ExampleApp
  # This is an example of bundling Zif::UI::Input together with a descriptive label and a background sprite
  class FormField < Zif::CompoundSprite
    attr_accessor :input, :background, :label, :max_length

    def initialize(name: Zif.unique_name('form_field'), x: 0, y: 0, label: 'Input: ', char_width: 10)
      super(name)
      @x = x
      @y = y

      @label = Zif::UI::Label.new(label, size: 0, r: 255, g: 255, b: 255)
      @label.x = 0
      @label.y = 25

      @input = Zif::UI::Input.new('Input Placeholder', size: 0).tap do |i|
        i.x = @label.max_width + 5
        i.y = 25
        i.color = [0, 0, 0].freeze
        i.has_focus = false
        i.transform = ->(text_key) { transform_key(text_key) }
      end

      @background = Zif::Sprite.new.tap do |bg|
        bg.x = @input.x - 5
        bg.y = 0
        bg.w = 20 + (char_width * 10)
        bg.h = 30
        bg.path = 'sprites/white_1.png'
      end

      lose_focus

      @w = @label.max_width + @background.w
      @h = @background.h
      @max_length = char_width
      @on_mouse_up = lambda do |_sprite, _point|
        gain_focus
      end

      @labels = [@label, @input]
      @sprites = [@background]
    end

    def gain_focus
      @input.has_focus = true
      @background.r = 255
      @background.b = 255
      @background.g = 255
    end

    def lose_focus
      @input.has_focus = false
      @background.r = 55
      @background.b = 55
      @background.g = 55
    end

    def transform_key(text_key)
      return nil if max_length.positive? && @input.text.length >= max_length

      text_key
    end
  end
end
