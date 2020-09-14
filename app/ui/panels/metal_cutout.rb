# The Kenney UI Space pack included this inset cutout, desgned to partition the metal panel.
# This is a nine-slice where the left/right/bottom edges are just fill and don't need to be defined.
class MetalCutout < Zif::NinePanel
  SPRITES_PATH = 'sprites/kenney-uipack-space/danhealy-modified'.freeze
  TOP_WIDTH = 7
  BOTTOM_WIDTH = 6

  def self.min_width
    TOP_WIDTH + 1 + TOP_WIDTH
  end

  def self.min_height
    TOP_WIDTH + 1 + BOTTOM_WIDTH
  end

  def initialize(target_name, width, height)
    super(target_name)

    @min_width  = MetalCutout.min_width
    @min_height = MetalCutout.min_height

    resize(width, height)

    self.upper_left_corner = Zif::Sprite.new.tap do |s|
      s.x = 0
      s.y = @height - TOP_WIDTH
      s.w = TOP_WIDTH
      s.h = TOP_WIDTH
      s.path = "#{SPRITES_PATH}/plate_top_corner.png"
    end

    self.upper_right_corner = Zif::Sprite.new.tap do |s|
      s.x = @width - TOP_WIDTH
      s.y = @height - TOP_WIDTH
      s.w = TOP_WIDTH
      s.h = TOP_WIDTH
      s.path = "#{SPRITES_PATH}/plate_top_corner.png"
      s.flip_horizontally = true
    end

    self.lower_right_corner = Zif::Sprite.new.tap do |s|
      s.x = @width - BOTTOM_WIDTH
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
      s.y = @height - TOP_WIDTH
      s.w = @width - 2 * TOP_WIDTH
      s.h = TOP_WIDTH
      s.path = "#{SPRITES_PATH}/plate_top_edge.png"
    end

    # Need to create the bottom edge so that we don't overlap the corners
    self.lower_edge = Zif::Sprite.new.tap do |s|
      s.x = BOTTOM_WIDTH
      s.y = 0
      s.w = @width - 2 * BOTTOM_WIDTH
      s.h = BOTTOM_WIDTH
      s.path = "#{SPRITES_PATH}/plate_center.png"
    end

    # No left/right edge, just fill

    @fill = Zif::Sprite.new.tap do |s|
      s.x = 0
      s.y = BOTTOM_WIDTH
      s.w = @width
      s.h = @height - BOTTOM_WIDTH - TOP_WIDTH
      s.path = "#{SPRITES_PATH}/plate_center.png"
    end

    redraw
  end
end
