module ExampleApp
  # The Kenney UI Space pack included this inset cutout, desgned to partition the metal panel.
  # This is a nine-slice where the left/right/bottom edges are just fill and don't need to be defined.
  class MetalCutout < Zif::NinePanel
    SPRITES_PATH = 'sprites/kenney-uipack-space/danhealy-modified'.freeze
    TOP_WIDTH = 7
    BOTTOM_WIDTH = 6

    def initialize(width, height, name=Zif.random_name('metal_cutout'))
      super(name)

      self.upper_left_corner = Zif::Sprite.new.tap do |s|
        s.x = 0
        s.w = TOP_WIDTH
        s.h = TOP_WIDTH
        s.path = "#{SPRITES_PATH}/plate_top_corner.png"
      end

      self.upper_right_corner = Zif::Sprite.new.tap do |s|
        s.w = TOP_WIDTH
        s.h = TOP_WIDTH
        s.path = "#{SPRITES_PATH}/plate_top_corner.png"
        s.flip_horizontally = true
      end

      self.lower_right_corner = Zif::Sprite.new.tap do |s|
        s.y = 0
        s.w = BOTTOM_WIDTH
        s.h = BOTTOM_WIDTH
        s.path = "#{SPRITES_PATH}/plate_bottom_corner.png"
        s.flip_horizontally = true
      end

      self.lower_left_corner = Zif::Sprite.new.tap do |s|
        s.x = 0
        s.y = 0
        s.w = BOTTOM_WIDTH
        s.h = BOTTOM_WIDTH
        s.path = "#{SPRITES_PATH}/plate_bottom_corner.png"
      end

      self.upper_edge = Zif::Sprite.new.tap do |s|
        s.x = TOP_WIDTH
        s.h = TOP_WIDTH
        s.path = "#{SPRITES_PATH}/plate_top_edge.png"
      end

      # Need to create the bottom edge so that we don't overlap the corners
      self.lower_edge = Zif::Sprite.new.tap do |s|
        s.x = BOTTOM_WIDTH
        s.y = 0
        s.h = BOTTOM_WIDTH
        s.path = "#{SPRITES_PATH}/plate_center.png"
      end

      # No left/right edge, just fill

      @fill = Zif::Sprite.new.tap do |s|
        s.x = 0
        s.y = BOTTOM_WIDTH
        s.path = "#{SPRITES_PATH}/plate_center.png"
      end
      resize(width, height)
    end

    def resize_width(width)
      return if @w == width

      @w = width

      upper_right_corner.x = @w - TOP_WIDTH
      lower_right_corner.x = @w - BOTTOM_WIDTH
      upper_edge.w         = @w - 2 * TOP_WIDTH
      lower_edge.w         = @w - 2 * BOTTOM_WIDTH
      @fill.w              = @w
    end

    def resize_height(height)
      return if @h == height

      @h = height

      upper_left_corner.y  = @h - TOP_WIDTH
      upper_right_corner.y = @h - TOP_WIDTH
      upper_edge.y         = @h - TOP_WIDTH
      @fill.h              = @h - BOTTOM_WIDTH - TOP_WIDTH
    end
  end
end
