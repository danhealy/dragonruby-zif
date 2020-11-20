module Zif
  # The Camera is given a set of layer sprites, typically these are the containing_sprites of large render targets.
  # It zooms these sprites to fit the viewable area of the screen.  It can be zoomed in and out using the scroll wheel.
  # It is responsible for directing the layers to reposition based on camera movements.
  class Camera
    include Zif::Actionable

    attr_accessor :target_name

    attr_accessor :layers, :layer_index

    attr_accessor :max_x, :max_y, :min_x, :min_y, :target_x, :target_y, :max_w, :max_h,
                  :max_zoom_in, :max_zoom_out, :zoom_step, :zoom_steps, :native_screen_width, :native_screen_height

    attr_reader :pos_x, :pos_y, :cur_w, :cur_h

    attr_accessor :velocity_x, :velocity_y, :last_camera_movement, :last_follow,
                  :follow_margins, :follow_duration, :follow_easing

    DEFAULT_SCREEN_WIDTH  = 1280
    DEFAULT_SCREEN_HEIGHT = 720

    # Setup vars, min/max camera position, arbitrary initial x/y
    # Width/height should be an integer multiple of 16:9 ratio!
    def initialize(target_name,
                   layer_sprites,
                   starting_width=DEFAULT_SCREEN_WIDTH,
                   starting_height=DEFAULT_SCREEN_HEIGHT,
                   initial_x=4000,
                   initial_y=2000)
      @target_name = target_name

      @native_screen_width  = DEFAULT_SCREEN_WIDTH
      @native_screen_height = DEFAULT_SCREEN_HEIGHT

      # Camera views a game-window-sized chunk of target at zoom level 1.0
      # These mirror the source_w/h attrs on the sprite layers
      @cur_w = starting_width
      @cur_h = starting_height
      @max_w = layer_sprites.map(&:w).max
      @max_h = layer_sprites.map(&:h).max

      @max_x = @max_w - @cur_w
      @max_y = @max_h - @cur_h

      @layers = layer_sprites.map do |layer|
        layer.assign(
          w: @native_screen_width,
          h: @native_screen_height
        )
      end

      # These values are the allowable extremes for zooming, described as a multiple of the native screen width/height
      @max_zoom_in  = 0.5
      @max_zoom_out = 2.0

      # Each scroll action will increase or decrease zoom factor by this amount:
      @zoom_steps = [0.5, 0.8, 1.0, 1.28, 1.6, 2.0]
      # Index of above
      @zoom_step = 2

      self.cur_w = starting_width
      self.cur_h = starting_height

      @min_x = 0
      @min_y = 0
      @pos_x = 0
      @pos_y = 0

      @velocity_x = 0
      @velocity_y = 0

      # Default follow params
      @follow_margins  = [300, 600, 300, 600] # These values will be multiplied by the zoom factor
      @follow_duration = 0.5.seconds
      @follow_easing   = :smooth_stop

      # Following will not work unless registered with an ActionService
      $game&.services&.named(:action_service)&.register_actionable(self)

      move(initial_x, initial_y)
    end

    def min_view_rect
      [(@native_screen_width * @max_zoom_in).to_i, (@native_screen_height * @max_zoom_in).to_i]
    end

    def max_view_rect
      [(@native_screen_width * @max_zoom_out).to_i, (@native_screen_height * @max_zoom_out).to_i]
    end

    def full_view_rect
      [@cur_w, @cur_h]
    end

    def each_layer(&_block)
      @layers.each do |layer|
        yield layer
      end
    end

    # Panning
    #########

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

    # To support moving the default zoom point while following something
    def follow_x
      @last_follow[0]
    end

    def follow_x=(x)
      @last_follow[0] = x
    end

    def follow_y
      @last_follow[1]
    end

    def follow_y=(y)
      @last_follow[1] = y
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

    def start_following(sprite)
      # We want to start following the leading sprite if it reaches the margins:
      top_margin, right_margin, down_margin, left_margin = @follow_margins

      top_margin, right_margin = Zif.position_math(:mult, [top_margin, right_margin], zoom_factor)
      down_margin, left_margin = Zif.position_math(:mult, [down_margin, left_margin], zoom_factor)

      relative_x = (sprite.x - @pos_x).to_i
      relative_y = (sprite.y - @pos_y).to_i

      @target_x = if relative_x < left_margin
                    -(left_margin - relative_x)
                  elsif relative_x > (@cur_w - right_margin)
                    relative_x - (@cur_w - right_margin)
                  else
                    0
                  end

      @target_y = if relative_y < down_margin
                    -(down_margin - relative_y)
                  elsif relative_y > (@cur_h - top_margin)
                    relative_y - (@cur_h - top_margin)
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
      ) { @last_follow = sprite.center }
      run(@last_camera_movement)
    end

    def center_screen(around=center)
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

    def center(from=pos)
      Zif.add_positions(
        from,
        Zif.position_math(
          :idiv,
          [@cur_w, @cur_h],
          [2, 2]
        )
      )
    end

    # Zooming
    #########

    # cur_w and cur_h setters will clamp based on max zoom, update @max_x/y, and then finally modify the camera layers
    def cur_w=(w)
      @cur_w = [[w, min_view_rect[0]].max, max_view_rect[0]].min
      @max_x = @max_w - @cur_w
      # puts "Camera: w clamped to #{w} -> #{@cur_w}.  Max x #{@max_x}"
      each_layer { |layer| layer.source_w = @cur_w }
    end

    def cur_h=(h)
      @cur_h = [[h, min_view_rect[1]].max, max_view_rect[1]].min
      @max_y = @max_h - @cur_h
      # puts "Camera: h clamped to #{h} -> #{@cur_h}.  Max y #{@max_y}"
      each_layer { |layer| layer.source_h = @cur_h }
    end

    # A zoom factor of 1.0 corresponds to this resolution
    def zoom_unit
      [@native_screen_width, @native_screen_height]
    end

    # This method is used as a hook for the InputService, when given this obj with #register_scrollable.
    # This could be used to zoom in and out based on where the mouse is pointed - currently ignored
    # Feel free to override if you need this behavior, or submit a PR to split the Camera for this feature.
    # By default, it will attempt to zoom to either the last followed object, or center of the screen
    def scrolled?(_point, direction)
      # translated_point = translate_pos(point)
      # puts "Camera scrolled: #{point}->#{translated_point} #{direction}"
      if direction == :down
        zoom_out # (translated_point)
      else
        zoom_in # (translated_point)
      end
    end

    def zoom_out(point=(@last_follow || center))
      @zoom_step = [@zoom_step+1, @zoom_steps.length - 1].min
      zoom_to(@zoom_steps[@zoom_step], point)
    end

    def zoom_in(point=(@last_follow || center))
      @zoom_step = [@zoom_step-1, 0].max
      zoom_to(@zoom_steps[@zoom_step], point)
    end

    def zoom_to(factor=1.0, point=(@last_follow || center))
      base_mult = (factor.round(2) * 80)
      self.cur_w = (base_mult * 16)
      self.cur_h = (base_mult * 9)

      # puts "#zoom_to: Zoomed to #{zoom_factor}"

      center_screen(point)
    end

    # Returns a float, where 1.0 means we are zoomed to the native screen resolution
    # This value is compared against @max_zoom_out and @max_zoom_in when zooming.
    def zoom_factor
      Zif.position_math(:fdiv, [@cur_w, @cur_h], zoom_unit)
    end

    # From window x/y to map x/y
    def translate_pos(given)
      Zif.add_positions(Zif.position_math(:mult, given, zoom_factor), pos)
    end
  end
end
