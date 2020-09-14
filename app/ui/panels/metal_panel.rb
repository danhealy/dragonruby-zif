# The Kenney UI Space pack contains these metal panels which have a colorful tab in the upper left.
# This is a bit more complex than a normal nine-slice, since the top edge will actually have 3 parts
# So we are using NinePanelEdge for this, and regular sprites for the other 8 sections.
class MetalPanel < Zif::NinePanel
  attr_accessor :upper_edge_panel

  SPRITES_PATH = 'sprites/kenney-uipack-space/danhealy-modified'.freeze
  VALID_COLORS = %i[blue green red yellow].freeze

  BIG_CORNER = 32
  SMALL_CORNER = 16
  TRANSITION_WIDTH = 12

  def self.min_width
    BIG_CORNER + 1 + TRANSITION_WIDTH + 1 + SMALL_CORNER
  end

  def self.min_height
    BIG_CORNER + 1 + SMALL_CORNER
  end

  def initialize(target_name, width, height, label=nil, color=:blue, _tabbed=true)
    super(target_name)

    color = VALID_COLORS.include?(color) ? color : :blue

    @min_width  = MetalPanel.min_width
    @min_height = MetalPanel.min_height
    resize(width, height)

    @upper_edge_panel = Zif::NinePanelEdge.new("#{target_name}_upper_edge")
    @upper_edge_panel.left_edge_path    = "#{SPRITES_PATH}/metal_#{color}_side.png"
    @upper_edge_panel.left_edge_height  = BIG_CORNER
    @upper_edge_panel.transition_path   = "#{SPRITES_PATH}/metal_#{color}_side_transition.png"
    @upper_edge_panel.transition_height = BIG_CORNER
    @upper_edge_panel.transition_width  = TRANSITION_WIDTH
    @upper_edge_panel.right_edge_path   = "#{SPRITES_PATH}/metal_side.png"
    @upper_edge_panel.right_edge_height = SMALL_CORNER
    @upper_edge_panel.init_sprites
    upper_edge_panel_sprites = @upper_edge_panel.stretch(
      BIG_CORNER,
      @height - BIG_CORNER,
      width - BIG_CORNER - SMALL_CORNER
    )

    self.upper_edge = upper_edge_panel_sprites

    self.right_edge = Zif::Sprite.new.tap do |s|
      s.x = BIG_CORNER + upper_edge_panel.width
      s.y = SMALL_CORNER
      s.w = SMALL_CORNER
      s.h = @height - 2 * SMALL_CORNER
      s.path = "#{SPRITES_PATH}/metal_side_right.png"
    end

    self.lower_edge = Zif::Sprite.new.tap do |s|
      s.x = SMALL_CORNER
      s.y = 0
      s.w = @width - 2 * SMALL_CORNER
      s.h = SMALL_CORNER
      s.path = "#{SPRITES_PATH}/metal_side.png"
      s.flip_vertically = true
    end

    self.left_edge = Zif::Sprite.new.tap do |s|
      s.x = 0
      s.y = SMALL_CORNER
      s.w = SMALL_CORNER
      s.h = @height - 2 * SMALL_CORNER
      s.path = "#{SPRITES_PATH}/metal_side_right.png"
      s.flip_horizontally = true
    end

    self.upper_left_corner = Zif::Sprite.new.tap do |s|
      s.x = 0
      s.y = @height - BIG_CORNER
      s.w = BIG_CORNER
      s.h = BIG_CORNER
      s.path = "#{SPRITES_PATH}/metal_#{color}_corner.png"
    end

    self.upper_right_corner = Zif::Sprite.new.tap do |s|
      s.x = @width - SMALL_CORNER
      s.y = @height - SMALL_CORNER
      s.w = SMALL_CORNER
      s.h = SMALL_CORNER
      s.path = "#{SPRITES_PATH}/metal_corner.png"
      s.flip_horizontally = true
    end

    self.lower_right_corner = Zif::Sprite.new.tap do |s|
      s.x = @width - SMALL_CORNER
      s.y = 0
      s.w = SMALL_CORNER
      s.h = SMALL_CORNER
      s.path = "#{SPRITES_PATH}/metal_corner.png"
      s.flip_horizontally = true
      s.flip_vertically = true
    end

    self.lower_left_corner = Zif::Sprite.new.tap do |s|
      s.x = 0
      s.y = 0
      s.w = SMALL_CORNER
      s.h = SMALL_CORNER
      s.path = "#{SPRITES_PATH}/metal_corner.png"
      s.flip_vertically = true
    end

    @fill = Zif::Sprite.new.tap do |s|
      s.x = SMALL_CORNER
      s.y = SMALL_CORNER
      s.w = @width - 2 * SMALL_CORNER
      s.h = @height - 2 * SMALL_CORNER
      s.path = "#{SPRITES_PATH}/metal_center.png"
    end

    if label
      margin_x = 10
      top_margin = 4
      available_width = @upper_edge_panel.left_edge.w + (upper_left_corner.w - margin_x)
      header = FutureLabel.new(label, -1, 0).tap do |l|
        l.text = l.truncate(available_width)
      end

      @labels << header.label_attrs.merge(
        {
          x: margin_x,
          y: @height - top_margin
        }
      )
    end

    redraw
  end
end
