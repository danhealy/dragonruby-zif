module ExampleApp
  # It's a progress bar!
  # A shadow appears for the full length.
  # Filling the shadow is a bar with fixed edges and stretchy center.
  # Setting the progress causes a redraw.
  # If progress is zero, the filled bar disappears.
  class ProgressBar < Zif::CompoundSprite
    SPRITES_PATH = 'sprites/kenney-uipack-space/PNG'.freeze

    attr_accessor :color, :orientation, :filled_bar, :shadow

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
    # TODO: :vertical not yet supported.. pull requests welcome.
    def initialize(name=Zif.unique_name('progress_bar'), width=100, progress=0.0, color=:blue, orientation=:horizontal)
      super(name)

      @progress = [[progress, 1.0].min, 0.0].max
      @orientation = orientation
      @shadow = []
      @filled_bar = []
      @h = HEIGHT

      @shadow_left = Zif::Sprite.new.tap do |s|
        s.x = 0
        s.y = 0
        s.w = EDGE_MARGIN
        s.h = HEIGHT
        s.path = "#{SPRITES_PATH}/#{SPRITE_NAMES[@orientation]}_shadow_left.png"
      end

      @shadow_mid = Zif::Sprite.new.tap do |s|
        s.x = EDGE_MARGIN
        s.y = 0
        s.h = HEIGHT
        s.path = "#{SPRITES_PATH}/#{SPRITE_NAMES[@orientation]}_shadow_mid.png"
      end

      @shadow_right = Zif::Sprite.new.tap do |s|
        s.y = 0
        s.w = EDGE_MARGIN
        s.h = HEIGHT
        s.path = "#{SPRITES_PATH}/#{SPRITE_NAMES[@orientation]}_shadow_right.png"
      end

      @shadow = [@shadow_left, @shadow_mid, @shadow_right]

      @filled_bar_left = Zif::Sprite.new.tap do |s|
        s.x = 0
        s.y = 0
        s.w = EDGE_MARGIN
        s.h = HEIGHT
      end

      @filled_bar_mid = Zif::Sprite.new.tap do |s|
        s.x = EDGE_MARGIN
        s.y = 0
        s.h = HEIGHT
      end

      @filled_bar_edge = Zif::Sprite.new.tap do |s|
        s.y = 0
        s.w = EDGE_MARGIN
        s.h = HEIGHT
      end

      @filled_bar = [@filled_bar_left, @filled_bar_mid, @filled_bar_edge]

      @sprites = @shadow + @filled_bar

      change_color(color)
      resize_width(width)
    end

    def change_color(color)
      @color = VALID_COLORS.include?(color) ? color : :blue

      @filled_bar_left.path = "#{SPRITES_PATH}/#{SPRITE_NAMES[@orientation]}_#{@color}_left.png"
      @filled_bar_mid.path  = "#{SPRITES_PATH}/#{SPRITE_NAMES[@orientation]}_#{@color}_mid.png"
      @filled_bar_edge.path = "#{SPRITES_PATH}/#{SPRITE_NAMES[@orientation]}_#{@color}_right.png"
    end

    def apply_progress
      cur_width = (@progress * (@w - 2 * EDGE_MARGIN)).round
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
    end

    # alias for actions
    def width=(new_width)
      resize_width(new_width)
    end

    def width
      @w
    end

    def resize_width(width)
      return if @w == width

      @w = width

      @shadow_mid.w   = @w - (2 * EDGE_MARGIN)
      @shadow_right.x = @w - EDGE_MARGIN
      apply_progress
    end
  end
end
