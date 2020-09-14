# The Kenney UI Space pack has transparent panels with optional cut corners.
# This is a normal nine slice where each corner has two options.
class GlassPanel < Zif::NinePanel
  SPRITES_PATH = 'sprites/kenney-uipack-space/danhealy-modified'.freeze
  WIDTH = 16

  def self.min_width
    WIDTH + 1 + WIDTH
  end

  def self.min_height
    min_width
  end

  def initialize(target_name, width, height, cut_corners=[false, false, false, false])
    super(target_name)

    @min_width  = GlassPanel.min_width
    @min_height = GlassPanel.min_height

    resize(width, height)

    self.upper_left_corner = Zif::Sprite.new.tap do |s|
      s.x = 0
      s.y = @height - WIDTH
      s.w = WIDTH
      s.h = WIDTH
      s.path = "#{SPRITES_PATH}/glass_#{cut_corners[3] ? 'cut' : 'round'}_corner.png"
    end

    self.upper_right_corner = Zif::Sprite.new.tap do |s|
      s.x = @width - WIDTH
      s.y = @height - WIDTH
      s.w = WIDTH
      s.h = WIDTH
      s.path = "#{SPRITES_PATH}/glass_#{cut_corners[2] ? 'cut' : 'round'}_corner.png"
      s.flip_horizontally = true
    end

    self.lower_right_corner = Zif::Sprite.new.tap do |s|
      s.x = @width - WIDTH
      s.y = 0
      s.w = WIDTH
      s.h = WIDTH
      s.path = "#{SPRITES_PATH}/glass_#{cut_corners[1] ? 'cut' : 'round'}_corner.png"
      s.flip_vertically = true
      s.flip_horizontally = true
    end

    self.lower_left_corner = Zif::Sprite.new.tap do |s|
      s.x = 0
      s.y = 0
      s.w = WIDTH
      s.h = WIDTH
      s.path = "#{SPRITES_PATH}/glass_#{cut_corners[0] ? 'cut' : 'round'}_corner.png"
      s.flip_vertically = true
    end

    self.upper_edge = Zif::Sprite.new.tap do |s|
      s.x = WIDTH
      s.y = @height - WIDTH
      s.w = @width - 2 * WIDTH
      s.h = WIDTH
      s.path = "#{SPRITES_PATH}/glass_side.png"
    end

    self.right_edge = Zif::Sprite.new.tap do |s|
      s.x = @width - WIDTH
      s.y = WIDTH
      s.w = WIDTH
      s.h = @height - 2 * WIDTH
      s.path = "#{SPRITES_PATH}/glass_side_right.png"
    end

    self.lower_edge = Zif::Sprite.new.tap do |s|
      s.x = WIDTH
      s.y = 0
      s.w = @width - 2 * WIDTH
      s.h = WIDTH
      s.path = "#{SPRITES_PATH}/glass_side.png"
      s.flip_vertically = true
    end

    self.left_edge = Zif::Sprite.new.tap do |s|
      s.x = 0
      s.y = WIDTH
      s.w = WIDTH
      s.h = @height - 2 * WIDTH
      s.path = "#{SPRITES_PATH}/glass_side_right.png"
      s.flip_horizontally = true
    end

    @fill = Zif::Sprite.new.tap do |s|
      s.x = WIDTH
      s.y = WIDTH
      s.w = @width - 2 * WIDTH
      s.h = @height - 2 * WIDTH
      s.path = "#{SPRITES_PATH}/glass_center.png"
    end

    redraw
  end
end
