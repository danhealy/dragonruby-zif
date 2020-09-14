module Zif
  # The Camera is given a set of layer sprites, typically these are the containing_sprites of large render targets.
  # It zooms these sprites to fit the viewable area of the screen.
  # It is responsible for directing the layers to reposition based on camera movements.
  class Camera
    include Zif::Actionable

    attr_accessor :target_name

    attr_accessor :layers, :layer_index

    attr_accessor :max_x, :max_y, :min_x, :min_y, :target_x, :target_y, :zoomed,
                  :prezoomed_pos, :cur_w, :cur_h, :max_view_width, :max_view_height

    attr_reader :pos_x, :pos_y

    attr_accessor :velocity_x, :velocity_y, :last_camera_movement, :follow_margins, :follow_duration, :follow_easing

    DEFAULT_SCREEN_WIDTH  = 1280
    DEFAULT_SCREEN_HEIGHT = 720

    # Setup vars, min/max camera position, arbitrary initial x/y
    def initialize(target_name,
                   layer_sprites,
                   max_view_width=DEFAULT_SCREEN_WIDTH,
                   max_view_height=DEFAULT_SCREEN_HEIGHT,
                   initial_x=4000,
                   initial_y=2000)
      @target_name = target_name

      @max_view_width = max_view_width
      @max_view_height = max_view_height

      @max_x = layer_sprites.map(&:w).max - @max_view_width
      @max_y = layer_sprites.map(&:h).max - @max_view_height

      @layers = layer_sprites.map do |layer|
        layer.assign(
          w:        @max_view_width,
          h:        @max_view_height,
          source_w: @max_view_width,
          source_h: @max_view_height
        )
      end

      @prezoomed_pos = [0, 0]

      @min_x = 0
      @min_y = 0
      @pos_x = 0
      @pos_y = 0

      # Camera views a game-window-sized chunk of target
      # These mirror the source_w/h attrs on the sprite layers
      @cur_w = @max_view_width
      @cur_h = @max_view_height

      @velocity_x = 0
      @velocity_y = 0

      # Default follow params
      @follow_margins  = [300, 600, 300, 600]
      @follow_duration = 0.5.seconds
      @follow_easing   = :smooth_stop

      # Following will not work unless registered with an ActionService
      $game&.services&.named(:action_service)&.register_actionable(self)

      move(initial_x, initial_y)
    end

    def full_view_rect
      [@max_view_width, @max_view_height]
    end

    def each_layer(&_block)
      @layers.each do |layer|
        yield layer
      end
    end

    # To support Actions being run on pos_x and pos_y (clamped):
    def pos_x=(x)
      @pos_x = [[x, @min_x].max, @max_x].min
      # puts "Camera: x clamped to #{x} -> #{@pos_x}"
      each_layer { |layer| layer.source_x = @pos_x }
    end

    def pos_y=(y)
      @pos_y = [[y, @min_y].max, @max_y].min
      # puts "Camera: y clamped to #{y} -> #{@pos_y}"
      each_layer { |layer| layer.source_y = @pos_y }
    end

    # Adjust pos_x and pos_y together, return difference
    def move(x, y)
      orig_pos_x = @pos_x
      orig_pos_y = @pos_y

      self.pos_x = x
      self.pos_y = y

      [@pos_x - orig_pos_x, @pos_y - orig_pos_y]
    end

    # Relative positional change where [1, 1] means add 1 to x/y instead of (1,1)
    # Accepts nil to support behavior of directional_vector
    def move_rel(x=nil, y=nil)
      return unless x && y

      self.pos_x = @pos_x + x.round
      self.pos_y = @pos_y + y.round
    end

    def zoom_factor
      Zif.position_math(:fdiv, [@cur_w, @cur_h], full_view_rect)
    end

    # From window x/y to map x/y
    def translate_pos(given)
      Zif.add_positions(Zif.position_math(:mult, given, zoom_factor), pos)
    end

    def start_following(sprite)
      # We want to start following the leading sprite if it reaches the margins:
      top_margin, right_margin, down_margin, left_margin = @follow_margins

      relative_x = (sprite.x - @pos_x).to_i
      relative_y = (sprite.y - @pos_y).to_i

      @target_x = if relative_x < left_margin
                    -(left_margin - relative_x)
                  elsif relative_x > right_margin
                    relative_x - right_margin
                  else
                    0
                  end

      @target_y = if relative_y < down_margin
                    -(down_margin - relative_y)
                  elsif relative_y > top_margin
                    relative_y - top_margin
                  else
                    0
                  end

      return if @target_x.zero? && @target_y.zero?

      @actions.delete(@last_camera_movement) if @last_camera_movement

      # puts "Camera#start_following: Running action #{{pos_x: @pos_x + @target_x, pos_y: @pos_y + @target_y}}"
      @last_camera_movement = new_action(
        {
          pos_x: @pos_x + @target_x,
          pos_y: @pos_y + @target_y
        },
        @follow_duration,
        @follow_easing
      )
      run(@last_camera_movement)
    end

    def center_screen(around)
      center_to = Zif.sub_positions(
        around,
        Zif.position_math(
          :idiv,
          [@cur_w, @cur_h],
          [2, 2]
        )
      )

      move(*center_to)
    end

    def pos
      [@pos_x, @pos_y]
    end
  end
end
