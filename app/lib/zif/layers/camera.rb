module Zif
  module Layers
    # Designed to be used with {Zif::Layers::LayerGroup}.
    #
    # The Camera is given a set of sprites, typically the containing sprites for a set of {Zif::Layers::Layerable}s.
    #
    # It zooms these sprites to fit the viewable area of the screen.  It can be zoomed in and out using the scroll
    # wheel.  It is responsible for directing the layers to reposition based on camera movements.
    #
    # This class includes {Zif::Actions::Actionable}, so you can pan the camera using a {Zif::Actions::Action}.
    class Camera
      include Zif::Actions::Actionable

      # @return [Array<Zif::Sprite>] The layer sprites this camera will move in unison.
      attr_accessor :layers

      # @return [Integer] The minimum X value the {layers} +source_x+ can have, typically +0+
      attr_accessor :min_x
      # @return [Integer] The minimum Y value the {layers} +source_y+ can have, typically +0+
      attr_accessor :min_y
      # @return [Integer] Of the given {layers}, the largest width value
      attr_accessor :max_w
      # @return [Integer] Of the given {layers}, the largest height value
      attr_accessor :max_h

      # @return [Float] The maximum zoom in level. Defaults to 0.5.  A value of 1.0 is no zoom at all.
      attr_accessor :max_zoom_in
      # @return [Float] The maximum zoom out level. Defaults to 2.0.  A value of 1.0 is no zoom at all.
      attr_accessor :max_zoom_out
      # @return [Integer] The index of {zoom_steps} pointing to the current zoom level.
      attr_accessor :zoom_step
      # @return [Array<Float>] An ordered array of discrete zoom levels.  Defaults to +[0.5, 0.8, 1.0, 1.28, 1.6, 2.0]+
      attr_accessor :zoom_steps

      # @todo Right now, the native screen size can't be changed.
      # @return [Integer] The native width of the screen, defaults to 1280
      attr_reader :native_screen_width
      # @return [Integer] The native height of the screen, defaults to 720
      attr_reader :native_screen_height

      # @return [Float] The current X position of the camera (lower left, maps to +source_x+ on layers)
      attr_reader :pos_x
      # @return [Float] The current Y position of the camera (lower left, maps to +source_y+ on layers)
      attr_reader :pos_y
      # @return [Float] The current width of the camera (maps to +source_w+ on layers)
      attr_reader :cur_w
      # @return [Float] The current height of the camera (maps to +source_h+ on layers)
      attr_reader :cur_h

      # @return [Integer] This is {max_w} subtracted by {cur_w}: The maximum X value the layers +source_x+ can have
      attr_accessor :max_x
      # @return [Integer] This is {max_h} subtracted by {cur_h}: The maximum Y value the layers +source_y+ can have
      attr_accessor :max_y

      # @return [Zif::Actions::Action] The most recent camera movement {Zif::Actions::Action}.
      attr_accessor :last_camera_movement
      # @return [Float] The relative change in X the camera is moving towards with {last_camera_movement}
      attr_accessor :target_x
      # @return [Float] The relative change in Y the camera is moving towards with {last_camera_movement}
      attr_accessor :target_y

      # @return [Array<Float>] The center point +[x, y]+ of the last followed sprite.  Used to center zooming.
      attr_accessor :last_follow
      # @return [Array<Integer>] The margins on the screen which will stop camera panning. +[top, right, bottom, left]+
      #   These values are multiplied by the zoom factor when used.
      #   Defaults to +[300, 600, 300, 600]+
      attr_accessor :follow_margins
      # @return [Integer] How many ticks should camera following take?  Defaults to 0.5 seconds.
      attr_accessor :follow_duration
      # @return [Symbol] The easing function ({Zif::Actions::Action::EASING_FUNCS}) to use for camera following.
      attr_accessor :follow_easing

      DEFAULT_SCREEN_WIDTH  = 1280
      DEFAULT_SCREEN_HEIGHT = 720

      # Setup vars, min/max camera position, arbitrary initial x/y
      # Width/height should be an integer multiple of 16:9 ratio!
      # This class expects to register itself with the {Zif::Services::ActionService} during initialize,
      # at +$game.services.named(:action_service)+
      # @param [Array<Zif::Sprite>] layer_sprites {layers}
      #   The width and height of these will be assigned to the screen parameters
      # @param [Integer] starting_width Sets {cur_w}
      # @param [Integer] starting_height Sets {cur_h}
      # @param [Integer] initial_x The initial X position of the camera {pos_x}, set via {move}
      # @param [Integer] initial_y The initial Y position of the camera {pos_y}, set via {move}
      def initialize(layer_sprites:,
                     starting_width: DEFAULT_SCREEN_WIDTH,
                     starting_height: DEFAULT_SCREEN_HEIGHT,
                     initial_x: 4000,
                     initial_y: 2000)

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

        # Default follow params
        @follow_margins  = [300, 600, 300, 600] # These values will be multiplied by the zoom factor
        @follow_duration = 0.5.seconds
        @follow_easing   = :smooth_stop

        # Following will not work unless registered with an ActionService
        $game&.services&.named(:action_service)&.register_actionable(self)

        move(initial_x, initial_y)
      end


      # @return [Array<Integer>] +[w, h]+ The minimum width and height of the camera viewport, assuming fully zoomed in
      def min_view_rect
        [(@native_screen_width * @max_zoom_in).to_i, (@native_screen_height * @max_zoom_in).to_i]
      end

      # @return [Array<Integer>] +[w, h]+ The maximum width and height of the camera viewport, assuming fully zoomed out
      def max_view_rect
        [(@native_screen_width * @max_zoom_out).to_i, (@native_screen_height * @max_zoom_out).to_i]
      end

      # @return [Array<Integer>] +[{cur_w}, {cur_h}]+
      def full_view_rect
        [@cur_w, @cur_h]
      end

      # @param [Block] _block The block to execute on each element of {layers}
      # @return [Enumerator] Iterate over each element of {layers}
      def each_layer(&_block)
        @layers.each do |layer|
          yield layer
        end
      end

      # To support Actions being run on pos_x and pos_y (clamped):
      # Set the X position and set the {layers} +source_x+ value based on that.
      # @param [Float] x The value to set to {pos_x}, this value is clamped by {min_x} and {max_x}
      def pos_x=(x)
        @pos_x = [[x, @min_x].max, @max_x].min
        # puts "Camera: x clamped to #{x} -> #{@pos_x}"
        each_layer { |layer| layer.source_x = @pos_x }
      end

      # Set the Y position and set the {layers} +source_y+ value based on that.
      # @param [Float] y The value to set to {pos_y}, this value is clamped by {min_y} and {max_y}
      def pos_y=(y)
        @pos_y = [[y, @min_y].max, @max_y].min
        # puts "Camera: y clamped to #{y} -> #{@pos_y}"
        each_layer { |layer| layer.source_y = @pos_y }
      end

      # To support moving the default zoom point while following something
      # @return [Float] The X value of {last_follow}
      def follow_x
        @last_follow[0]
      end

      # @param [Float] x Set the X value of {last_follow}
      def follow_x=(x)
        @last_follow[0] = x
      end

      # @return [Float] The Y value of {last_follow}
      def follow_y
        @last_follow[1]
      end

      # @param [Float] y Set the Y value of {last_follow}
      def follow_y=(y)
        @last_follow[1] = y
      end

      # Adjust pos_x and pos_y together, return difference
      # @param [Float] x Set {pos_x}
      # @param [Float] y Set {pos_y}
      # @return [Array<Float>] +[x, y]+ array, the difference between the given params and the original position
      def move(x, y)
        orig_pos_x = @pos_x
        orig_pos_y = @pos_y

        self.pos_x = x
        self.pos_y = y

        [@pos_x - orig_pos_x, @pos_y - orig_pos_y]
      end

      # Relative positional change where [1, 1] means add 1 to x/y instead of (1,1)
      # Accepts nil to support behavior of directional_vector
      # @param [Float] x Set {pos_x} to the current value plus this
      # @param [Float] y Set {pos_y} to the current value plus this
      def move_rel(x=nil, y=nil)
        return unless x && y

        self.pos_x = @pos_x + x.round
        self.pos_y = @pos_y + y.round
      end

      # Cause the Camera to start an {Zif::Actions::Action} on itself to pan {pos_x} and {pos_y} towards the center
      # point of the given +sprite+.  Obeys {follow_margins}.  Stops any existing {last_camera_movement}.  Panning will
      # take {follow_duration} and use {follow_easing}.
      # @param [Zif::Sprite] sprite The sprite to be followed.
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

        stop_action(@last_camera_movement) if @last_camera_movement

        # puts "Camera#start_following: Running action #{{pos_x: @pos_x + @target_x, pos_y: @pos_y + @target_y}}"
        @last_camera_movement = new_action(
          {
            pos_x: @pos_x + @target_x,
            pos_y: @pos_y + @target_y
          },
          duration: @follow_duration,
          easing:   @follow_easing
        ) { @last_follow = sprite.center }

        run_action(@last_camera_movement)
      end

      # @param [Array<Float>] around +[x, y]+ positional array to center the screen around, using {move}
      #   Defaults to {center}
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

      # @return [Array<Float>] +[{pos_x}, {pos_y}]
      def pos
        [@pos_x, @pos_y]
      end


      # Calculates the difference between +[{cur_w}/2, {cur_h}/2]+ and +from+
      # @param [Array<Float>] from +[x, y]+, defaults to {pos}
      # @return [Array<Float>] The difference between +[{cur_w}/2, {cur_h}/2]+ and +from+
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

      # Set {cur_w} but clamp based on {min_view_rect} and {max_view_rect}. Then update {@max_x}.
      # Finally, it modifies the camera layers +source_w+.
      # @param [Integer] w The new width of the Camera viewport.
      def cur_w=(w)
        @cur_w = [[w, min_view_rect[0]].max, max_view_rect[0]].min
        @max_x = @max_w - @cur_w
        # puts "Camera: w clamped to #{w} -> #{@cur_w}.  Max x #{@max_x}"
        each_layer { |layer| layer.source_w = @cur_w }
      end

      # Set {cur_y} but clamp based on {min_view_rect} and {max_view_rect}. Then update {@max_y}.
      # Finally, it modifies the camera layers +source_h+.
      # @param [Integer] h The new height of the Camera viewport.
      def cur_h=(h)
        @cur_h = [[h, min_view_rect[1]].max, max_view_rect[1]].min
        @max_y = @max_h - @cur_h
        # puts "Camera: h clamped to #{h} -> #{@cur_h}.  Max y #{@max_y}"
        each_layer { |layer| layer.source_h = @cur_h }
      end

      # A zoom factor of 1.0 corresponds to this resolution
      # @return [Array<Integer>] +[{native_screen_width}, {native_screen_height}]+
      def zoom_unit
        [@native_screen_width, @native_screen_height]
      end

      # This method is used as a hook for {Zif::Services::InputService}, when given this obj with
      # {Zif::Services::InputService#register_scrollable}.
      # @todo This could be used to zoom in and out based on where the mouse is pointed - currently ignored.
      #   Feel free to override if you need this behavior, or submit a PR to split the Camera for this feature.
      # By default, it will attempt to zoom to either the last followed object, or center of the screen.
      # @param [Array<Float>] _point The point the mouse was at when scrolled, currently ignored
      # @param [Symbol] direction The direction of scroll, either +:up+ or +:down+
      def scrolled?(_point, direction)
        # translated_point = translate_pos(point)
        # puts "Camera scrolled: #{point}->#{translated_point} #{direction}"
        if direction == :down
          zoom_out # (translated_point)
        else
          zoom_in # (translated_point)
        end
      end

      # Zooms out by a single value in {zoom_steps}, around the given +point+
      # @param [Array<Float>] point +[x, y]+ The point to center the zoom out around.
      def zoom_out(point=(@last_follow || center))
        @zoom_step = [@zoom_step + 1, @zoom_steps.length - 1].min
        zoom_to(@zoom_steps[@zoom_step], point)
      end

      # Zooms in by a single value in {zoom_steps}, around the given +point+
      # @param [Array<Float>] point +[x, y]+ The point to center the zoom in around.
      def zoom_in(point=(@last_follow || center))
        @zoom_step = [@zoom_step - 1, 0].max
        zoom_to(@zoom_steps[@zoom_step], point)
      end

      # Zooms to a specific zoom +factor+, around the given +point+.
      # You probably should prefer using {zoom_out} and {zoom_in} to do stepwise zooms instead of this method.
      # @param [Float] factor The zoom factor to zoom to.  Ideally this would be a value in {zoom_steps}.
      # @param [Array<Float>] point +[x, y]+ The point to center the zoom in around.
      def zoom_to(factor=1.0, point=(@last_follow || center))
        base_mult = (factor.round(2) * 80)
        self.cur_w = (base_mult * 16)
        self.cur_h = (base_mult * 9)

        # puts "#zoom_to: Zoomed to #{zoom_factor}"

        center_screen(point)
      end

      # The current zoom factor, this value is compared against {max_zoom_out} and {max_zoom_in} when zooming.
      # @return [Float] The current zoom factor.  A value of +1.0+ means we are zoomed to the native screen resolution
      #   Lower values mean we are zoomed in, higher values are zoomed out.
      def zoom_factor
        Zif.position_math(:fdiv, [@cur_w, @cur_h], zoom_unit)
      end

      # Translate a 2 element point from the screen's perspective to the map's perspective
      # @param [Array<Float>] given +[x, y]+ positional array from the screen's perspective
      # @return [Array<Float>] +[x, y]+ positional array from the map's perspective, taking into account camera position
      #   and zoom level.
      def translate_pos(given)
        Zif.add_positions(Zif.position_math(:mult, given, zoom_factor), pos)
      end
    end
  end
end
