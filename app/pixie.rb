module ExampleApp
  # This is the little spinning square which follows the Avatar on the World scene.
  class Pixie < Zif::Sprite
    def initialize
      super
      @w = 10
      @h = 10
      @source_x = 0
      @source_y = 0
      @source_w = 10
      @source_h = 10
      @a = 255
      randomize_color
      @path = 'sprites/white_1.png'
    end

    def random_duration
      30 + rand(90)
    end

    def randomize_color
      @r, @g, @b = Zif.rand_rgb(100, 255)
    end

    def spin
      @spin_action = new_action(
        {angle: 359},
        duration: random_duration,
        easing:   :linear,
        repeat:   :forever
      )
      run_action(@spin_action)
    end

    def float_to(obj)
      run_action(
        new_action(
          {x: :center_x, y: :center_y},
          follow:   obj,
          duration: random_duration,
          easing:   :linear
        ) do
          # Repeat with new durations and color.
          @x = 1659
          @y = 1659
          randomize_color
          @spin_action.duration = random_duration
          float_to(obj)
        end
      )
    end
  end
end
