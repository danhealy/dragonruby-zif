module ExampleApp
  # The Kenney UI Space pack has transparent panels with optional cut corners.
  # This is a normal nine slice where each corner has two options.
  class GlassPanel < Zif::NinePanel
    SPRITES_PATH = 'sprites/kenney-uipack-space/danhealy-modified'.freeze
    CUT_CORNER   = "#{SPRITES_PATH}/glass_cut_corner.png".freeze
    ROUND_CORNER = "#{SPRITES_PATH}/glass_round_corner.png".freeze
    WIDTH = 16

    attr_accessor :cuts

    def initialize(width, height, cut_corners=[false, false, false, false], name=Zif.random_name('glass_panel'))
      super(name)

      self.upper_left_corner = Zif::Sprite.new.tap do |s|
        s.x = 0
        s.w = WIDTH
        s.h = WIDTH
      end

      self.upper_right_corner = Zif::Sprite.new.tap do |s|
        s.w = WIDTH
        s.h = WIDTH
        s.flip_horizontally = true
      end

      self.lower_right_corner = Zif::Sprite.new.tap do |s|
        s.y = 0
        s.w = WIDTH
        s.h = WIDTH
        s.flip_vertically = true
        s.flip_horizontally = true
      end

      self.lower_left_corner = Zif::Sprite.new.tap do |s|
        s.x = 0
        s.y = 0
        s.w = WIDTH
        s.h = WIDTH
        s.flip_vertically = true
      end

      self.upper_edge = Zif::Sprite.new.tap do |s|
        s.x = WIDTH
        s.h = WIDTH
        s.path = "#{SPRITES_PATH}/glass_side.png"
      end

      self.right_edge = Zif::Sprite.new.tap do |s|
        s.y = WIDTH
        s.w = WIDTH
        s.path = "#{SPRITES_PATH}/glass_side_right.png"
      end

      self.lower_edge = Zif::Sprite.new.tap do |s|
        s.x = WIDTH
        s.y = 0
        s.h = WIDTH
        s.path = "#{SPRITES_PATH}/glass_side.png"
        s.flip_vertically = true
      end

      self.left_edge = Zif::Sprite.new.tap do |s|
        s.x = 0
        s.y = WIDTH
        s.w = WIDTH
        s.path = "#{SPRITES_PATH}/glass_side_right.png"
        s.flip_horizontally = true
      end

      @fill = Zif::Sprite.new.tap do |s|
        s.x = WIDTH
        s.y = WIDTH
        s.path = "#{SPRITES_PATH}/glass_center.png"
      end

      resize(width, height)
      change_cuts(cut_corners)
    end

    def change_cuts(cut_corners)
      @cuts = cut_corners
      lower_left_corner.path  = cut_corners[0] ? CUT_CORNER : ROUND_CORNER
      lower_right_corner.path = cut_corners[1] ? CUT_CORNER : ROUND_CORNER
      upper_right_corner.path = cut_corners[2] ? CUT_CORNER : ROUND_CORNER
      upper_left_corner.path  = cut_corners[3] ? CUT_CORNER : ROUND_CORNER
    end

    def resize_width(width)
      return if @w == width

      @w = width

      upper_right_corner.x = @w - WIDTH
      lower_right_corner.x = @w - WIDTH
      upper_edge.w         = @w - 2 * WIDTH
      right_edge.x         = @w - WIDTH
      lower_edge.w         = @w - 2 * WIDTH
      @fill.w = @w - 2 * WIDTH
    end

    def resize_height(height)
      return if @h == height

      @h = height

      upper_left_corner.y  = @h - WIDTH
      upper_right_corner.y = @h - WIDTH
      upper_edge.y         = @h - WIDTH
      right_edge.h         = @h - 2 * WIDTH
      left_edge.h          = @h - 2 * WIDTH
      @fill.h = @h - 2 * WIDTH
    end
  end
end
