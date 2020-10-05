module Zif
  # This keeps track of any clickable sprites that need to be informed of a click.
  # #process_click iterates through clickables and passes #clicked? to each.
  # It is expected #clicked? will call the click handlers if present
  class InputService
    attr_accessor :target_name

    def initialize
      @last_mouse_bits = 0
      reset_clickables
    end

    def reset_clickables
      @clickables = []
      @expecting_mouse_up = []
    end

    def register_clickable(clickable)
      @clickables << clickable
      clickable
    end

    def remove_clickable(clickable)
      @clickables.delete(clickable)
    end

    # rubocop:disable Metrics/PerceivedComplexity
    def process_click
      return if @clickables.empty?

      @mouse_point    = $gtk.args.inputs.mouse.point
      mouse_bits      = $gtk.args.inputs.mouse.button_bits
      mouse_up        = $gtk.args.inputs.mouse.up
      mouse_down      = $gtk.args.inputs.mouse.down # mouse_bits > @last_mouse_bits
      mouse_only_down = mouse_down && !mouse_up

      return unless mouse_down || mouse_up || @expecting_mouse_up.any?

      kind = if mouse_up
               :up
             else
               (mouse_down ? :down : :changed)
             end

      awaiting_clicks = mouse_only_down ? @clickables : @expecting_mouse_up

      # puts "Zif::InputService#process_click: #{@mouse_point} point, #{mouse_bits} bits, kind: #{kind}."
      # puts "                                 #{awaiting_clicks.count} registered"

      awaiting_clicks.each do |clickable|
        # puts "Zif::InputService#process_click: clickable: #{clickable.name} -> #{clickable.rect}"

        clicked_sprite = clickable.clicked?(@mouse_point, kind)
        next unless clicked_sprite

        @expecting_mouse_up |= [clicked_sprite] if mouse_only_down

        # puts "Zif::InputService#process_click: #{@expecting_mouse_up.length} expecting"
        # puts "Zif::InputService#process_click: -> sprite handled click #{clicked_sprite}"
      end

      @expecting_mouse_up = [] if mouse_up
      @last_mouse_bits = mouse_bits
    end
    # rubocop:enable Metrics/PerceivedComplexity
  end
end
