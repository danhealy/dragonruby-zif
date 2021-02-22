module ExampleApp
  # The Kenney UI Space pack contains these metal panels which have a colorful tab in the upper left.
  # This is a bit more complex than a normal nine-slice, since the top edge will actually have 3 parts
  # So we are using NinePanelEdge for this, and regular sprites for the other 8 sections.
  class MetalPanel < Zif::NinePanel
    attr_accessor :upper_edge_panel, :header

    SPRITES_PATH = 'sprites/kenney-uipack-space/danhealy-modified'.freeze
    VALID_COLORS = %i[blue green red yellow].freeze

    BIG_CORNER = 32
    SMALL_CORNER = 16
    TRANSITION_WIDTH = 12

    def initialize(width, height, label=nil, color=:blue, name=Zif.random_name('metal_panel'))
      super(name)

      @upper_edge_panel = Zif::NinePanelEdge.new
      @upper_edge_panel.left_edge_height  = BIG_CORNER
      @upper_edge_panel.transition_height = BIG_CORNER
      @upper_edge_panel.transition_width  = TRANSITION_WIDTH
      @upper_edge_panel.right_edge_path   = "#{SPRITES_PATH}/metal_side.png"
      @upper_edge_panel.right_edge_height = SMALL_CORNER

      # Gotta define this first so we can set the color.
      self.upper_left_corner = Zif::Sprite.new.tap do |s|
        s.x = 0
        s.w = BIG_CORNER
        s.h = BIG_CORNER
      end

      change_color(color)
      @upper_edge_panel.init_sprites

      self.right_edge = Zif::Sprite.new.tap do |s|
        s.y = SMALL_CORNER
        s.w = SMALL_CORNER
        s.path = "#{SPRITES_PATH}/metal_side_right.png"
      end

      self.lower_edge = Zif::Sprite.new.tap do |s|
        s.x = SMALL_CORNER
        s.y = 0
        s.h = SMALL_CORNER
        s.path = "#{SPRITES_PATH}/metal_side.png"
        s.flip_vertically = true
      end

      self.left_edge = Zif::Sprite.new.tap do |s|
        s.x = 0
        s.y = SMALL_CORNER
        s.w = SMALL_CORNER
        s.path = "#{SPRITES_PATH}/metal_side_right.png"
        s.flip_horizontally = true
      end

      self.upper_right_corner = Zif::Sprite.new.tap do |s|
        s.w = SMALL_CORNER
        s.h = SMALL_CORNER
        s.path = "#{SPRITES_PATH}/metal_corner.png"
        s.flip_horizontally = true
      end

      self.lower_right_corner = Zif::Sprite.new.tap do |s|
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
        s.path = "#{SPRITES_PATH}/metal_center.png"
      end

      if label
        @header = FutureLabel.new(label, -1, 0)
        @header.x = 10
        @labels << @header
      end

      resize(width, height)

      self.upper_edge = @upper_edge_panel.sprites
    end

    def change_color(color)
      @color = VALID_COLORS.include?(color) ? color : :blue

      @upper_edge_panel.transition_path = "#{SPRITES_PATH}/metal_#{@color}_side_transition.png"
      @upper_edge_panel.left_edge_path  = "#{SPRITES_PATH}/metal_#{@color}_side.png"
      upper_left_corner.path = "#{SPRITES_PATH}/metal_#{@color}_corner.png"

      @upper_edge_panel.update_paths
    end

    def resize_width(width)
      return if @w == width

      @w = width

      @upper_edge_panel.resize_width(@w - BIG_CORNER - SMALL_CORNER)
      @upper_edge_panel.reposition(BIG_CORNER, @h - BIG_CORNER)

      right_edge.x         = BIG_CORNER + upper_edge_panel.width
      lower_edge.w         = @w - 2 * SMALL_CORNER
      upper_right_corner.x = @w - SMALL_CORNER
      lower_right_corner.x = @w - SMALL_CORNER
      @fill.w              = @w - 2 * SMALL_CORNER

      @header.truncate(@upper_edge_panel.left_edge.w + (upper_left_corner.w - @header.x))
    end

    def resize_height(height)
      return if @h == height

      @h = height

      @upper_edge_panel.reposition(BIG_CORNER, @h - BIG_CORNER)

      upper_right_corner.y = @h - SMALL_CORNER
      upper_left_corner.y  = @h - BIG_CORNER
      left_edge.h          = @h - 2 * SMALL_CORNER
      right_edge.h         = @h - 2 * SMALL_CORNER
      @fill.h              = @h - 2 * SMALL_CORNER
      @header.y            = @h - 4
    end
  end
end
