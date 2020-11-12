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

    @h = NORMAL_HEIGHT
    @pressed_height = PRESSED_HEIGHT - 1
    @label_y_offset = 0

    @normal_left = Zif::Sprite.new.tap do |s|
      s.x = 0
      s.y = 0
      s.w = EDGE_WIDTH
      s.h = NORMAL_HEIGHT
    end

    @normal_center = Zif::Sprite.new.tap do |s|
      s.x = EDGE_WIDTH
      s.y = 0
      s.h = NORMAL_HEIGHT
    end

    @normal_right = Zif::Sprite.new.tap do |s|
      s.y = 0
      s.w = EDGE_WIDTH
      s.h = NORMAL_HEIGHT
      s.flip_horizontally = true
    end

    @pressed_left = Zif::Sprite.new.tap do |s|
      s.x = 0
      s.y = 0
      s.w = EDGE_WIDTH
      s.h = PRESSED_HEIGHT
    end

    @pressed_center = Zif::Sprite.new.tap do |s|
      s.x = EDGE_WIDTH
      s.y = 0
      s.h = PRESSED_HEIGHT
    end

    @pressed_right = Zif::Sprite.new.tap do |s|
      s.y = 0
      s.w = EDGE_WIDTH
      s.h = PRESSED_HEIGHT
      s.flip_horizontally = true
    end

    resize_width(width)
    change_color(color)

    @normal  = [@normal_left,  @normal_center,  @normal_right]
    @pressed = [@pressed_left, @pressed_center, @pressed_right]

    if label_text
      @labels << FutureLabel.new(label_text, label_size, 1)
      recenter_label
      retruncate_label
    end

    unpress
  end

  # Width methods to support actions
  def width=(new_width)
    resize_width(new_width)
  end

  def width
    @w
  end

  def resize_width(width)
    return if @w == width

    @w = width
    view_actual_size!

    [@normal_center, @pressed_center].each do |center|
      center.w = @w - (2 * EDGE_WIDTH)
    end

    [@normal_right, @pressed_right].each do |r_edge|
      r_edge.x = @w - EDGE_WIDTH
    end

    recenter_label
    retruncate_label(2 * EDGE_WIDTH)
  end

  def change_color(color)
    @color = VALID_COLORS.include?(color) ? color : :blue

    [@normal_left, @normal_right].each do |edge|
      edge.path = "#{SPRITES_PATH}/button_normal_#{@color}_edge.png"
    end

    @normal_center.path = "#{SPRITES_PATH}/button_normal_#{@color}_center.png"

    [@pressed_left, @pressed_right].each do |edge|
      edge.path = "#{SPRITES_PATH}/button_pressed_#{@color}_edge.png"
    end

    @pressed_center.path = "#{SPRITES_PATH}/button_pressed_#{@color}_center.png"
  end
end
