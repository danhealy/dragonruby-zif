# Demonstrating usage of a CompoundSprite with actions
class CompoundSpriteTest < ZifExampleScene
  include Zif::Traceable

  attr_accessor :compound_sprite

  def initialize
    super
    @tracer_service_name = :tracer
    @next_scene = :ui_sample

    @compound_sprite = Zif::CompoundSprite.new.tap do |s|
      s.x = 100
      s.y = 100
      s.w = 800
      s.h = 400
      s.source_x = 0
      s.source_y = 0
      s.source_w = 800
      s.source_h = 400
    end

    @outline = $game.services[:sprite_registry].construct(:white_1).tap do |s|
      s.x = 100
      s.y = 100
      s.w = 800
      s.h = 400
      s.source_x = 0
      s.source_y = 0
      s.source_w = 800
      s.source_h = 400
      s.a = 30
    end

    [[0, 50], [100, 150], [0, 250]].each do |pos|
      dragon = $game.services[:sprite_registry].construct('dragon_1').tap do |s|
        s.name = "dragon_#{pos.inspect}"
        s.x = pos[0]
        s.y = pos[1]
      end

      finish_pos = 1000 - pos[0]

      dragon.run(
        Zif::Sequence.new(
          [
            dragon.new_action(
              {x: finish_pos}, 10.seconds, :smooth_start
            ) { dragon.flip_horizontally = true },
            dragon.new_action(
              {x: pos[0]}, 10.seconds, :smooth_stop
            ) { dragon.flip_horizontally = false }
          ],
          :forever
        )
      )

      dragon.run(
        Zif::Sequence.new(
          [
            dragon.new_action({y: pos[1] + 300}, 5.seconds, :smooth_start),
            dragon.new_action({y: pos[1] - 300}, 5.seconds, :smooth_stop)
          ],
          :forever
        )
      )

      dragon.new_basic_animation(
        :fly,
        1.upto(4).map { |i| ["dragon_#{i}", 4] } + 3.downto(2).map { |i| ["dragon_#{i}", 4] }
      )

      dragon.run_animation_sequence(:fly)

      @compound_sprite.sprites << dragon
    end

    dragon_label = Zif::Label.new('A Thunder of Dragons', 0, 1).tap do |label|
      label.x = 50
      label.y = 0
      label.r = 255
      label.g = 255
      label.b = 255
      label.a = 255
    end

    dragon_label.run(
      Zif::Sequence.new(
        [
          dragon_label.new_action({x: 1000}, 10.seconds, :smooth_start),
          dragon_label.new_action({x: 0   }, 10.seconds, :smooth_stop)
        ],
        :forever
      )
    )

    @compound_sprite.labels << dragon_label

    [@outline, @compound_sprite].each do |sprite|
      sprite.run(
        Zif::Sequence.new(
          [
            sprite.new_action({x: 300}, 6.seconds, :linear),
            sprite.new_action({x: 100}, 6.seconds, :linear)
          ],
          :forever
        )
      )

      sprite.run(
        Zif::Sequence.new(
          [
            sprite.new_action({y: 300}, 3.seconds, :linear),
            sprite.new_action({y: 100}, 3.seconds, :linear)
          ],
          :forever
        )
      )
    end
  end

  def prepare_scene
    super

    @compound_sprite.sprites.each do |dragon|
      $game.services[:action_service].register_actionable(dragon)
    end
    @compound_sprite.labels.each do |dragon_label|
      $game.services[:action_service].register_actionable(dragon_label)
    end

    $game.services[:action_service].register_actionable(@compound_sprite)
    $game.services[:action_service].register_actionable(@outline)

    $gtk.args.outputs.static_sprites << @outline
    $gtk.args.outputs.static_sprites << @compound_sprite
  end

  def perform_tick
    mark('#perform_tick: Start')
    $gtk.args.outputs.background_color = [0, 0, 0, 0]

    @compound_sprite.source_h += 100 if $gtk.args.inputs.keyboard.key_up.up
    @compound_sprite.source_h -= 100 if $gtk.args.inputs.keyboard.key_up.down
    @compound_sprite.source_w += 100 if $gtk.args.inputs.keyboard.key_up.right
    @compound_sprite.source_w -= 100 if $gtk.args.inputs.keyboard.key_up.left

    # rubocop:disable Layout/LineLength
    $gtk.args.outputs.labels << { x: 8, y: 100, text: 'Up/Down: Modify source_h.  Right/Left: Modify source_w.', r: 255, g: 255, b: 255, a: 255}
    $gtk.args.outputs.labels << { x: 8, y: 80, text: "Compund Sprite: #{@compound_sprite.rect} -> #{@compound_sprite.source_rect}.  Zoom #{@compound_sprite.zoom_factor}", r: 255, g: 255, b: 255, a: 255}
    # rubocop:enable Layout/LineLength

    mark('#perform_tick: Finished')
    super
  end
end
