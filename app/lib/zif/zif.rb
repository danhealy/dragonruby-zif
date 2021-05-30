# This is the namespace for the Zif library, and in the +app/lib/zif/zif.rb+ file are some miscellaneous helper methods
module Zif
  GTK_COMPATIBLE_VERSION = '2.14'.freeze

  # @param [Numeric] i
  # @param [Numeric] max
  # @return [Numeric] +i+ upto +max+, otherwise the greater of the reflection off +max+, or +0+
  # @example The boomerang goes to 5 and then back to 0
  #   Zif.boomerang(2, 5) # => 2
  #   Zif.boomerang(5, 5) # => 5
  #   Zif.boomerang(6, 5) # => 4
  #   Zif.boomerang(7, 5) # => 3
  #   Zif.boomerang(10, 5) # => 0
  #   Zif.boomerang(15, 5) # => 0
  def self.boomerang(i, max)
    return i if i <= max

    return [max - (i - max), 0].max
  end

  # @param [Array<Numeric>] a
  # @param [Array<Numeric>] b
  # @return [Array<Numeric>] The addition of the two 2-element array inputs
  # @example
  #  # [4, 8] + [1, 1] = [5, 9]
  #  Zif.add_positions([4, 8], [1, 1]) # => [5, 9]
  def self.add_positions(a, b)
    position_math(:plus, a, b)
  end

  # @param [Array<Numeric>] a
  # @param [Array<Numeric>] b
  # @return [Array<Numeric>] The subtraction of the two 2-element array inputs
  # @example
  #  # [4, 8] - [1, 1] = [3, 7]
  #   Zif.sub_positions([4, 8], [1, 1]) # => [3, 7]
  def self.sub_positions(a, b)
    position_math(:minus, a, b)
  end

  # @example Dividing one array from another
  #   # This works because #fdiv is a method you can call on Numeric
  #   Zif.position_math(:fdiv, [5, 6], [2, 2]) # => [2.5, 3.0]
  #
  # @example Multiplying two arrays together
  #   # #mult is another method.  You can use any method the elements of +a+ respond to.
  #   Zif.position_math(:mult, [5, 6], [2, 2]) # => [10, 12]
  #
  # @param [Symbol] op A method to call against the elements of +a+ given the argument the matching element of +b+
  # @param [Array<Numeric>] a
  # @param [Array<Numeric>] b
  # @return [Array<Numeric>] The result of the operation
  def self.position_math(op=:plus, a=[1, 1], b=[2, 3])
    [
      a[0].send(op, b[0]),
      a[1].send(op, b[1])
    ]
  end

  # @example Gimme a number between -5 and +5
  #   Zif.relative_rand(10) # => -3
  # @param [Numeric] x A number representing the extent of the range of values (Remember that 0 is included)
  # @return [Integer] A random number between negative 1/2 of +x+ and positive 1/2 of +x+
  def self.relative_rand(x)
    (rand(x + 1) - x.fdiv(2)).round
  end

  # @param [Numeric] base The base value of the color, it cannot go lower than this
  # @param [Numeric] max The maximum value of the color, it cannot go higher than this
  # @return [Array<Numeric>] A three-element array of random numbers between base and max
  def self.rand_rgb(base, max)
    3.times.map { base + rand(max - base) }
  end

  # Taken from http://martin.ankerl.com/2009/12/09/how-to-create-random-colors-programmatically
  # @param [Integer] h Hue, valid range 0-359
  # @param [Integer] s Saturation, valid range 0-100
  # @param [Integer] v Value, valid range 0-100
  # @return [Array<Numeric>] A three-element array of integers from 0-255 representing the RBG value of the given hsv.
  def self.hsv_to_rgb(h, s, v)
    h = [359, [h, 0].max].min.fdiv(360)
    s = s.fdiv(100)
    v = v.fdiv(100)

    h_i = (h * 6).to_i

    f = h * 6 - h_i
    p = v * (1 - s)
    q = v * (1 - f * s)
    t = v * (1 - (1 - f) * s)

    case h_i
    when 0
      r = v
      g = t
      b = p
    when 1
      r = q
      g = v
      b = p
    when 2
      r = p
      g = v
      b = t
    when 3
      r = p
      g = q
      b = v
    when 4
      r = t
      g = p
      b = v
    when 5
      r = v
      g = p
      b = q
    end
    [(r * 255).to_i, (g * 255).to_i, (b * 255).to_i]
  end

  # Implements the distance formula
  # @param [Numeric] x1
  # @param [Numeric] y1
  # @param [Numeric] x2
  # @param [Numeric] y2
  # @return [Float] The distance between these two points
  def self.distance(x1, y1, x2, y2)
    Math.sqrt((x2 - x1)**2 + (y2 - y1)**2)
  end

  # @param [Numeric] x1
  # @param [Numeric] y1
  # @param [Numeric] x2
  # @param [Numeric] y2
  # @return [Float] The angle between these two points, in radians
  def self.radian_angle_between_points(x1, y1, x2, y2)
    Math.atan2(x2 - x1, y2 - y1)
  end

  # v2 default arguments are to 1d6+0
  # @example Roll some dice with a modifier
  #   Zif.roll_v2(dice: 4, sides: 16, modifier: 2)
  #   # We roll 8, 2, 3, 16.  Added together this is 29.  At the end, the modifier is added.
  #   # => 31
  # @param [Integer] dice
  # @param [Integer] sides
  # @param [Numeric] modifier
  # @return [Numeric] Chooses a number between +1+ and +sides+, +dice+ times, and then adds them together with +modifier+.
  def self.roll_v2(dice: 1, sides: 6, modifier: 0)
    roll(dice, sides, modifier)
  end

  # v2 default arguments are to 1d6
  # @example Roll some dice
  #   Zif.roll_raw_v2(dice: 4, sides: 16)
  #   # We roll 8, 2, 3, 16.  Added together this is 29.
  #   # => 29
  # @param [Integer] dice
  # @param [Integer] sides
  # @return [Numeric] Chooses a number between +1+ and +sides+, +dice+ times, and adds them together.
  def self.roll_raw_v2(dice: 1, sides: 6)
    roll_raw_v2(dice, sides)
  end

  # @deprecated
  # Default arguments will be changed to match {Zif.roll_v2} in 3.0.0+
  # @example Roll some dice with a modifier
  #   Zif.roll(dice: 4, sides: 16, modifier: 2)
  #   # We roll 8, 2, 3, 16.  Added together this is 29.  At the end, the modifier is added.
  #   # => 31
  # @param [Integer] dice
  # @param [Integer] sides
  # @param [Numeric] modifier
  # @return [Numeric] Chooses a number between +1+ and +sides+, +dice+ times, and then adds them together with +modifier+.
  def self.roll(dice: 4, sides: 16, modifier: 2)
    roll_raw(dice: dice, sides: sides) + modifier
  end

  # @deprecated
  # Default arguments will be changed to match {Zif.roll_raw_v2} in 3.0.0+
  # @example Roll some dice
  #   Zif.roll_raw(dice: 4, sides: 16)
  #   # We roll 8, 2, 3, 16.  Added together this is 29.
  #   # => 29
  # @param [Integer] dice
  # @param [Integer] sides
  # @return [Numeric] Chooses a number between +1+ and +sides+, +dice+ times, and adds them together.
  def self.roll_raw(dice: 4, sides: 16)
    dice.times.map { rand(sides) + 1 }.inject(0) { |z, memo| memo + z }
  end

  # @param [Symbol, String] type The prefix for the random string, typically this is called with a class name.
  # @return [String] Generates a unique string out of +type+, the current tick count, and an incrementing number.
  def self.unique_name(type='unknown')
    @names_used ||= 0
    "#{type}_#{Kernel.tick_count}_#{@names_used += 1}"
  end

  # @deprecated Usually you want to use {Zif::Actions::Action} instead
  def self.ease(t, total)
    Math.sin(((t / total.to_f) * Math::PI) / 2.0)
  end

  # Checks the running DragonRuby GTK version against {Zif::GTK_COMPATIBLE_VERSION}
  # If different, it prints a little warning.  This is invoked automatically by {Zif::Game#initialize}
  def self.check_compatibility
    return if $gtk.version == Zif::GTK_COMPATIBLE_VERSION

    puts '+-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-+'
    against_str = "This version of the Zif framework was tested against DRGTK '#{Zif::GTK_COMPATIBLE_VERSION}'"
    against_pad = [(77 - against_str.length).idiv(2), 0].max

    running_str = "You are running DragonRuby GTK Version '#{$gtk.version}'"
    running_pad = [(77 - running_str.length).idiv(2), 0].max

    puts "|#{' ' * against_pad}#{against_str}#{' ' * (against_pad.even? ? against_pad : against_pad + 1)}|"
    puts "|#{' ' * running_pad}#{running_str}#{' ' * (running_pad.even? ? running_pad : running_pad + 1)}|"
    puts '|                                                                             |'
    puts '| Please ensure you are using the latest versions of DRGTK and Zif:           |'
    puts '| DRGTK: http://dragonruby.herokuapp.com/toolkit/game                         |'
    puts '| Zif:   https://github.com/danhealy/dragonruby-zif/releases                  |'
    puts '+-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-+'
  end
end
