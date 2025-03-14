module TestHelpers
  def self.sprite_at(x, y, w, h)
    Zif::Sprite.new.tap do |result|
      result.x = x
      result.y = y
      result.w = w
      result.h = h
    end
  end

  def self.csprite_at(x, y, w, h)
    Zif::CompoundSprite.new.tap do |result|
      result.x = x
      result.y = y
      result.w = w
      result.h = h

      result.view_actual_size!
    end
  end
end
