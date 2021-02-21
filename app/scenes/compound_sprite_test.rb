# Demonstrating usage of a CompoundSprite with actions
# rubocop:disable Metrics/MethodLength
class CompoundSpriteTest < ZifExampleScene
  include Zif::Traceable

  attr_accessor :compound_sprite

  def initialize
    super
    @tracer_service_name = :tracer
    @next_scene = :ui_sample

    @compound_sprite = Zif::CompoundSprite.new.tap do |s|
      s.name = 'Test Sprite'
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

    @dragons = [[0, 50], [100, 150], [0, 250]].map do |pos|
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
              {x: finish_pos}, duration: 10.seconds, easing: :smooth_start
            ) { dragon.flip_horizontally = true },
            dragon.new_action(
              {x: pos[0]}, duration: 10.seconds, easing: :smooth_stop
            ) { dragon.flip_horizontally = false }
          ],
          :forever
        )
      )

      dragon.run(
        Zif::Sequence.new(
          [
            dragon.new_action({y: pos[1] + 300}, duration: 5.seconds, easing: :smooth_start),
            dragon.new_action({y: pos[1] - 300}, duration: 5.seconds, easing: :smooth_stop)
          ],
          :forever
        )
      )

      dragon.new_basic_animation(
        :fly,
        1.upto(4).map { |i| ["dragon_#{i}", 4] } + 3.downto(2).map { |i| ["dragon_#{i}", 4] }
      )

      dragon.run_animation_sequence(:fly)

      dragon
    end

    @compound_sprite.sprites += @dragons

    lead_dragon = @dragons[1]

    50.times do |i|
      _wait, layer = i.divmod(10)
      pixie = $game.services[:sprite_registry].construct(:white_1).tap do |s|
        s.x = lead_dragon.x
        s.y = lead_dragon.y
        s.w = 10
        s.h = 10
        s.source_x = 0
        s.source_y = 0
        s.source_w = 10
        s.source_h = 10
        s.a = 0
        s.r, s.g, s.b = Zif.rand_rgb(100, 255)
      end

      # Start spraying
      pixie.run(
        pixie.delayed_action(rand.seconds) do
          pixie_spray(pixie, layer)
        end
      )

      @compound_sprite.sprites << pixie
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
          dragon_label.new_action({x: 1000}, duration: 10.seconds, easing: :smooth_start),
          dragon_label.new_action({x: 0   }, duration: 10.seconds, easing: :smooth_stop)
        ],
        :forever
      )
    )

    @compound_sprite.labels << dragon_label

    [@outline, @compound_sprite].each do |sprite|
      sprite.run(
        Zif::Sequence.new(
          [
            sprite.new_action({x: 300}, duration: 6.seconds, easing: :linear),
            sprite.new_action({x: 100}, duration: 6.seconds, easing: :linear)
          ],
          :forever
        )
      )

      sprite.run(
        Zif::Sequence.new(
          [
            sprite.new_action({y: 300}, duration: 3.seconds, easing: :linear),
            sprite.new_action({y: 100}, duration: 3.seconds, easing: :linear)
          ],
          :forever
        )
      )
    end
  end

  def prepare_scene
    super

    @compound_sprite.sprites.each do |dragon| # and pixies
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
    $gtk.args.outputs.labels << { x: 4, y: 120, text: 'Up/Down: Modify source_h.  Right/Left: Modify source_w.', r: 255, g: 255, b: 255, a: 255}
    $gtk.args.outputs.labels << { x: 4, y: 100, text: "Compund Sprite: #{@compound_sprite.rect} -> #{@compound_sprite.source_rect}.  Zoom #{@compound_sprite.zoom_factor}", r: 255, g: 255, b: 255, a: 255}
    # rubocop:enable Layout/LineLength

    mark('#perform_tick: Finished')
    super
  end

  def pixie_spray(pix, layer)
    idx = rand(3)
    dir = @dragons[idx].flip_horizontally ? 1 : -1

    pix.x = @dragons[idx].center_x + (5 * layer) * dir
    pix.y = @dragons[idx].center_y - 10
    pix.a = 50
    pix.run(pix.new_action(
              {
                x:     pix.x + ((rand(100) + 20) * dir),
                angle: rand(360 * 5)
              },
              duration: 2.seconds,
              easing: :smooth_stop5
            ))
    pix.run(pix.new_action({y: pix.y + Zif.relative_rand(50)}, duration: 2.seconds, easing: :smooth_stop5))
    pix.run(
      pix.fade_out(rand.seconds) do
        pixie_spray(pix, layer)
      end
    )
  end
end
# rubocop:enable Metrics/MethodLength
