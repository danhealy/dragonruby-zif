# It's a progress bar!
# A shadow appears for the full length.
# Filling the shadow is a bar with fixed edges and stretchy center.
# Setting the progress causes a redraw.
# If progress is zero, the filled bar disappears.
class ProgressBar < Zif::ComplexSprite
  SPRITES_PATH = 'sprites/kenney-uipack-space/PNG'.freeze

  attr_accessor :filled_bar, :shadow
  attr_accessor :filled_bar_mid, :filled_bar_edge
  attr_accessor :color, :orientation, :max_width

  EDGE_MARGIN = 6
  HEIGHT = 26
  SPRITE_NAMES = {
    horizontal: 'barHorizontal',
    vertical:   'barVertical'
  }.freeze

  VALID_COLORS = %i[blue green red white yellow].freeze

  def self.min_width
    EDGE_MARGIN + 1 + EDGE_MARGIN
  end

  # Width and Height assume horizontal orientation, naming is inverted for vertical
  def initialize(target_name, width, progress=0.0, color=:blue, orientation=:horizontal)
    super(target_name)

    @render_target.bg_color = [255, 255, 255, 0]

    @orientation = orientation
    @progress = progress
    @color = VALID_COLORS.include?(color) ? color : :blue
    @shadow = []
    @filled_bar = []

    # TODO: :vertical not yet supported..
    if @orientation == :horizontal
      @min_width  = ProgressBar.min_width
      @min_height = HEIGHT
      resize(width, HEIGHT)
      @max_width = [width, @width].max
    end

    @shadow << Zif::Sprite.new.tap do |s|
      s.x = 0
      s.y = 0
      s.w = EDGE_MARGIN
      s.h = HEIGHT
      s.path = "#{SPRITES_PATH}/#{SPRITE_NAMES[@orientation]}_shadow_left.png"
    end

    @shadow << Zif::Sprite.new.tap do |s|
      s.x = EDGE_MARGIN
      s.y = 0
      s.w = @max_width - (2 * EDGE_MARGIN)
      s.h = HEIGHT
      s.path = "#{SPRITES_PATH}/#{SPRITE_NAMES[@orientation]}_shadow_mid.png"
    end

    @shadow << Zif::Sprite.new.tap do |s|
      s.x = @max_width - EDGE_MARGIN
      s.y = 0
      s.w = EDGE_MARGIN
      s.h = HEIGHT
      s.path = "#{SPRITES_PATH}/#{SPRITE_NAMES[@orientation]}_shadow_right.png"
    end

    @filled_bar_left = Zif::Sprite.new.tap do |s|
      s.x = 0
      s.y = 0
      s.w = EDGE_MARGIN
      s.h = HEIGHT
      s.path = "#{SPRITES_PATH}/#{SPRITE_NAMES[@orientation]}_#{@color}_left.png"
    end

    @filled_bar_mid = Zif::Sprite.new.tap do |s|
      s.x = EDGE_MARGIN
      s.y = 0
      s.h = HEIGHT
      s.path = "#{SPRITES_PATH}/#{SPRITE_NAMES[@orientation]}_#{@color}_mid.png"
    end

    @filled_bar_edge = Zif::Sprite.new.tap do |s|
      s.y = 0
      s.w = EDGE_MARGIN
      s.h = HEIGHT
      s.path = "#{SPRITES_PATH}/#{SPRITE_NAMES[@orientation]}_#{@color}_right.png"
    end

    @filled_bar = [@filled_bar_left, @filled_bar_mid, @filled_bar_edge]

    apply_progress
    redraw
  end

  def redraw
    @render_target.sprites = @shadow + @filled_bar
    draw_target
  end

  def apply_progress
    cur_width = (@progress * (@max_width - 2 * EDGE_MARGIN)).round
    if cur_width.zero?
      @filled_bar.each(&:hide)
    else
      @filled_bar.each(&:show)

      @filled_bar_mid.w  = cur_width
      @filled_bar_edge.x = cur_width + EDGE_MARGIN
    end
  end

  def progress=(new_progress)
    clamped_progress = [[new_progress, 1.0].min, 0.0].max
    return unless @progress != clamped_progress

    @progress = clamped_progress
    apply_progress
    redraw
  end
end
