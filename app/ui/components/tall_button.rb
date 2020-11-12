# A two-stage button, sized for all of the tall buttons in the Kenny UI pack.
class TallButton < Zif::TwoStageButton
  include Zif::Serializable
  SPRITES_PATH = 'sprites/kenney-uipack-fixed/danhealy-modified'.freeze
  VALID_COLORS = %i[blue green red yellow white].freeze

  EDGE_WIDTH = 6
  PRESSED_HEIGHT = 45
  NORMAL_HEIGHT = 49
  LABEL_Y_OFFSET = 4

  def self.min_width
    EDGE_WIDTH + 1 + EDGE_WIDTH
  end

  def initialize(name, width, color=:blue, label_text=nil, label_size=-1, &block)
    super(name, &block)
    @color = VALID_COLORS.include?(color) ? color : :blue

    @w = width
    @h = NORMAL_HEIGHT
    @pressed_height = PRESSED_HEIGHT - 1
    @label_y_offset = 0
    view_actual_size!

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
      s.w = @w - (2 * EDGE_WIDTH)
      s.h = NORMAL_HEIGHT
      s.path = "#{SPRITES_PATH}/button_normal_#{@color}_center.png"
    end

    @normal << Zif::Sprite.new.tap do |s|
      s.x = @w - EDGE_WIDTH
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
      s.w = @w - (2 * EDGE_WIDTH)
      s.h = PRESSED_HEIGHT
      s.path = "#{SPRITES_PATH}/button_pressed_#{@color}_center.png"
    end

    @pressed << Zif::Sprite.new.tap do |s|
      s.x = @w - EDGE_WIDTH
      s.y = 0
      s.w = EDGE_WIDTH
      s.h = PRESSED_HEIGHT
      s.path = "#{SPRITES_PATH}/button_pressed_#{@color}_edge.png"
      s.flip_horizontally = true
    end

    if label_text
      @labels << FutureLabel.new(label_text, label_size, 1)
      recenter_label
      label_text = label_text
    end

    unpress
  end

  def label_text=(text)
    label = @labels.first
    return unless label

    label.text = text
    recalculate_minimums
    label.text = label.truncate(@w - (2 * EDGE_WIDTH))
  end
end
