module ExampleApp
  # The Avatar is the player controllable sprite.
  class Avatar < Zif::Sprite
    attr_accessor :max_x, :max_y, :map_bounds
    attr_accessor :walking, :moving_to, :movement_action

    # rubocop:disable Layout/ExtraSpacing
    DIRECTIONS = {
      [ 0,  1] => :n,
      [ 0, -1] => :s,
      [ 1,  0] => :e,
      [-1,  0] => :w,

      [ 1,  1] => :e,
      [ 1, -1] => :e,
      [-1,  1] => :w,
      [-1, -1] => :w
    }.freeze
    # rubocop:enable Layout/ExtraSpacing

    WALK_SPEED = 8

    def initialize(proto, x=0, y=0, max_x=1280, max_y=720)
      super()
      assign(proto.to_h)
      stop_walking

      # Initial position
      @x = x
      @y = y
      @max_x = max_x
      @max_y = max_y

      @map_bounds = [[0, 0], Zif.sub_positions([@max_x, @max_y], wh)]

      new_basic_animation(
        named:               :fly,
        paths_and_durations: [1, 2, 3, 4, 3, 2].map { |i| ["dragon_#{i}", 4] }
      )
    end

    def moved_this_tick?
      @dirty
    end

    def perform_tick; end

    def cap_movement(to)
      [
        [[@x + to[0], @map_bounds[0][0]].max, @map_bounds[1][0]].min.floor,
        [[@y + to[1], @map_bounds[0][1]].max, @map_bounds[1][1]].min.floor
      ]
    end

    def start_walking(to=nil)
      @walking = true
      return unless to

      relative_to = Zif.sub_positions(to, xy)
      offset_to = Zif.sub_positions(relative_to, Zif.position_math(:idiv, wh, [2, 2]))

      @moving_to = cap_movement(offset_to)

      distance = Zif.distance(*xy, *@moving_to)
      duration = distance.fdiv(WALK_SPEED).ceil
      stop_action(@movement_action) if @movement_action

      @movement_action = new_action(
        {
          x: @moving_to[0],
          y: @moving_to[1]
        },
        duration: duration,
        easing:   :smooth_stop
      ) { stop_walking }

      run_action(@movement_action)
    end

    def stop_walking
      @walking = false
      @moving_to = nil
    end
  end
end
