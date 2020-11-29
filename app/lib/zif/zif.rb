# This is the namespace for the Zif library, and in this file are some miscellaneous helper methods
module Zif
  def self.boomerang(i, max)
    return i if i <= max

    return [max - (i - max), 0].max
  end

  def self.add_positions(a, b)
    position_math(:plus, a, b)
  end

  def self.sub_positions(a, b)
    position_math(:minus, a, b)
  end

  # Example => [1+2, 1+3] => [3, 4]
  def self.position_math(op=:plus, a=[1, 1], b=[2, 3])
    [
      a[0].send(op, b[0]),
      a[1].send(op, b[1])
    ]
  end

  def self.relative_rand(x)
    (rand(x) - x.fdiv(2)).round
  end

  def self.rand_rgb(base, max)
    3.times.map { base + rand(max - base) }
  end

  # http://martin.ankerl.com/2009/12/09/how-to-create-random-colors-programmatically
  # Ranges 0-359, 0-100, 0-100
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

  def self.distance(x1, y1, x2, y2)
    Math.sqrt((x2 - x1)**2 + (y2 - y1)**2)
  end

  def self.radian_angle_between_points(x1, y1, x2, y2)
    Math.atan2(x2 - x1, y2 - y1)
  end

  # Example => 4d16+2
  def self.roll(given_dice={dice: 4, sides: 16, modifier: 2})
    roll_raw(given_dice[:dice], given_dice[:sides]) + given_dice[:modifier]
  end

  # Example => 4d16
  def self.roll_raw(die=4, sides=16)
    die.times.map { rand(sides) + 1 }.inject(0) { |z, memo| memo + z }
  end

  def self.random_name(type='unknown')
    "#{type}_#{Kernel.tick_count}_#{rand(100_000)}"
  end

  # Usually you want to use Actions instead
  def self.ease(t, total)
    Math.sin(((t / total.to_f) * Math::PI) / 2.0)
  end
end
