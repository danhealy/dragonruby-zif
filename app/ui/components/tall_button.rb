# A two-stage button, sized for all of the tall buttons in the Kenny UI pack.
class TallButton < Zif::TwoStageButton
  include Zif::Serializable
  SPRITES_PATH = 'sprites/kenney-uipack-fixed/danhealy-modified'.freeze
  VALID_COLORS = %i[blue green red yellow white].freeze

  EDGE_WIDTH = 6
  PRESSED_HEIGHT = 45
  NORMAL_HEIGHT = 49
  LABEL_Y_OFFSET = 4
  LABEL_Y_PRESSED_OFFSET = 6

  def pressed_height
    PRESSED_HEIGHT
  end

  def normal_height
    NORMAL_HEIGHT
  end

  def label_y_offset
    LABEL_Y_OFFSET
  end

  def label_y_pressed_offset
    LABEL_Y_PRESSED_OFFSET
  end

  def self.min_width
    EDGE_WIDTH + 1 + EDGE_WIDTH
  end

  def initialize(target_name, width, color=:blue, label_text=nil, label_size=-1, &block)
    super(target_name, &block)

    @color = VALID_COLORS.include?(color) ? color : :blue
    @min_width = TallButton.min_width
    @min_height = [PRESSED_HEIGHT, NORMAL_HEIGHT].min

    resize(width, cur_height)

    @normal << Zif::Sprite.new.tap do |s|
      s.x = 0
      s.y = 0
      s.w = EDGE_WIDTH
      s.h = NORMAL_HEIGHT
      s.path = "#{SPRITES_PATH}/button_normal_#{@color}_edge.png"
    end

    @normal << Zif::Sprite.new.tap do |s|
      s.x = EDGE_WIDTH
      s.y = 0
      s.w = width - (2 * EDGE_WIDTH)
      s.h = NORMAL_HEIGHT
      s.path = "#{SPRITES_PATH}/button_normal_#{@color}_center.png"
    end

    @normal << Zif::Sprite.new.tap do |s|
      s.x = width - EDGE_WIDTH
      s.y = 0
      s.w = EDGE_WIDTH
      s.h = NORMAL_HEIGHT
      s.path = "#{SPRITES_PATH}/button_normal_#{@color}_edge.png"
      s.flip_horizontally = true
    end

    @pressed << Zif::Sprite.new.tap do |s|
      s.x = 0
      s.y = 0
      s.w = EDGE_WIDTH
      s.h = PRESSED_HEIGHT
      s.path = "#{SPRITES_PATH}/button_pressed_#{@color}_edge.png"
    end

    @pressed << Zif::Sprite.new.tap do |s|
      s.x = EDGE_WIDTH
      s.y = 0
      s.w = width - (2 * EDGE_WIDTH)
      s.h = PRESSED_HEIGHT
      s.path = "#{SPRITES_PATH}/button_pressed_#{@color}_center.png"
    end

    @pressed << Zif::Sprite.new.tap do |s|
      s.x = width - EDGE_WIDTH
      s.y = 0
      s.w = EDGE_WIDTH
      s.h = PRESSED_HEIGHT
      s.path = "#{SPRITES_PATH}/button_pressed_#{@color}_edge.png"
      s.flip_horizontally = true
    end

    if label_text
      @label = FutureLabel.new(label_text, label_size, 1).tap do |l|
        l.text = l.truncate(width - (2 * EDGE_WIDTH))
      end
    end

    redraw
  end

  def label_text=(text)
    @label.text = text
    redraw
  end
end
