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
    THICKNESS = 26
    SPRITE_NAMES = {
      horizontal: 'barHorizontal',
      vertical:   'barVertical'
    }.freeze

    VALID_COLORS = %i[blue green red white yellow].freeze

    def self.min_length
      EDGE_MARGIN + 1 + EDGE_MARGIN
    end

    # When orientation is horizontal, length is Width otherwise it is Height
    def initialize(name=Zif.unique_name('progress_bar'), length=100, progress=0.0, color=:blue, orientation=:horizontal)
      super(name)

      @progress = [[progress, 1.0].min, 0.0].max
      @orientation = orientation
      @shadow = []
      @filled_bar = []

      if horizontal?
        @h = THICKNESS
      else
        @w = THICKNESS
      end

      @shadow_lo = Zif::Sprite.new.tap do |s|
        s.x = 0
        s.y = 0

        if horizontal?
          s.w = EDGE_MARGIN
          s.h = THICKNESS
          s.path = "#{SPRITES_PATH}/#{SPRITE_NAMES[@orientation]}_shadow_left.png"
        else
          s.w = THICKNESS
          s.h = EDGE_MARGIN
          s.path = "#{SPRITES_PATH}/#{SPRITE_NAMES[@orientation]}_shadow_bottom.png"
        end
      end

      @shadow_mid = Zif::Sprite.new.tap do |s|
        if horizontal?
          s.x = EDGE_MARGIN
          s.y = 0
          s.h = THICKNESS
        else
          s.x = 0
          s.y = EDGE_MARGIN
          s.w = THICKNESS
        end
        s.path = "#{SPRITES_PATH}/#{SPRITE_NAMES[@orientation]}_shadow_mid.png"
      end

      @shadow_hi = Zif::Sprite.new.tap do |s|
        if horizontal?
          s.y = 0
          s.w = EDGE_MARGIN
          s.h = THICKNESS
          s.path = "#{SPRITES_PATH}/#{SPRITE_NAMES[@orientation]}_shadow_right.png"
        else
          s.x = 0
          s.w = THICKNESS
          s.h = EDGE_MARGIN
          s.path = "#{SPRITES_PATH}/#{SPRITE_NAMES[@orientation]}_shadow_top.png"
        end
      end

      @shadow = [@shadow_lo, @shadow_mid, @shadow_hi]

      @filled_bar_lo = Zif::Sprite.new.tap do |s|
        s.x = 0
        s.y = 0
        
        if horizontal?
          s.w = EDGE_MARGIN
          s.h = THICKNESS
        else
          s.w = THICKNESS
          s.h = EDGE_MARGIN
        end
      end

      @filled_bar_mid = Zif::Sprite.new.tap do |s|
        if horizontal?
          s.x = EDGE_MARGIN
          s.y = 0
          s.h = THICKNESS
        else
          s.x = 0
          s.y = EDGE_MARGIN
          s.w = THICKNESS
        end
      end

      @filled_bar_hi = Zif::Sprite.new.tap do |s|
        if horizontal?
          s.y = 0
          s.w = EDGE_MARGIN
          s.h = THICKNESS
        else
          s.x = 0
          s.w = THICKNESS
          s.h = EDGE_MARGIN
        end
      end

      @filled_bar = [@filled_bar_lo, @filled_bar_mid, @filled_bar_hi]

      @sprites = @shadow + @filled_bar

      change_color(color)
      resize_length(length)
    end

    def horizontal?
      @orientation == :horizontal
    end

    def change_color(color)
      @color = VALID_COLORS.include?(color) ? color : :blue

      @filled_bar_mid.path  = "#{SPRITES_PATH}/#{SPRITE_NAMES[@orientation]}_#{@color}_mid.png"

      if horizontal?
        @filled_bar_lo.path = "#{SPRITES_PATH}/#{SPRITE_NAMES[@orientation]}_#{@color}_left.png"
        @filled_bar_hi.path = "#{SPRITES_PATH}/#{SPRITE_NAMES[@orientation]}_#{@color}_right.png"
      else
        @filled_bar_lo.path = "#{SPRITES_PATH}/#{SPRITE_NAMES[@orientation]}_#{@color}_bottom.png"
        @filled_bar_hi.path = "#{SPRITES_PATH}/#{SPRITE_NAMES[@orientation]}_#{@color}_top.png"
      end
    end

    def apply_progress
      cur_length = (@progress * (length - 2 * EDGE_MARGIN)).round
      if cur_length.zero?
        @filled_bar.each(&:hide)
      else
        @filled_bar.each(&:show)

        if horizontal?
          @filled_bar_mid.w = cur_length
          @filled_bar_hi.x  = cur_length + EDGE_MARGIN
        else
          @filled_bar_mid.h = cur_length
          @filled_bar_hi.y  = cur_length + EDGE_MARGIN
        end
      end
    end

    def progress=(new_progress)
      clamped_progress = [[new_progress, 1.0].min, 0.0].max
      return unless @progress != clamped_progress

      @progress = clamped_progress
      apply_progress
    end

    # for actions
    def length=(new_length)
      resize_length(new_length)
    end

    def length
      horizontal? ? @w : @h
    end

    def resize_length(length)
      return if @w == length && horizontal? ||
        @h == length && !horizontal?

      if horizontal?
        @w = length
        @shadow_mid.w = @w - (2 * EDGE_MARGIN)
        @shadow_hi.x  = @w - EDGE_MARGIN
      else
        @h = length
        @shadow_mid.h = @h - (2 * EDGE_MARGIN)
        @shadow_hi.y  = @h - EDGE_MARGIN
      end

      apply_progress
    end
  end
end
