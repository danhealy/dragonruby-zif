module Zif
  # This keeps track of any clickable sprites that need to be informed of a click.
  # #process_click iterates through clickables and passes #clicked? to each.
  # It is expected #clicked? will call the click handlers if present
  class InputService
    attr_accessor :target_name

    def initialize
      @last_mouse_bits = 0
      reset
    end

    def reset
      @clickables = []
      @scrollables = []
      @absorb_list = []
      @expecting_mouse_up = []
    end

    # Clickable objects should respond to #clicked?(point, kind) and optionally #absorb_click?
    def register_clickable(clickable, absorb_click=nil)
      @clickables << clickable
      @absorb_list << clickable if absorb_click || (clickable.respond_to?(:absorb_click?) && clickable.absorb_click?)
      @clickables.sort! do |a, b|
        next 1 unless a&.respond_to?(:z)
        next -1 unless b&.respond_to?(:z)

        b.z <=> a.z
      end
      clickable
    end

    def remove_clickable(clickable)
      @clickables.delete(clickable)
    end

    # Scrollable objects should respond to #scroll?(point, direction) and optionally #absorb_scroll?
    def register_scrollable(scrollable, absorb_scroll=nil)
      @scrollables << scrollable

      if absorb_scroll || (scrollable.respond_to?(:absorb_scroll?) && scrollable.absorb_scroll?)
        @absorb_list << scrollable
      end

      @scrollables.sort! do |a, b|
        next 1 unless a&.respond_to?(:z)
        next -1 unless b&.respond_to?(:z)

        b.z <=> a.z
      end
      scrollable
    end

    def remove_scrollable(scrollable)
      @scrollables.delete(scrollable)
    end

    # rubocop:disable Metrics/PerceivedComplexity
    def process_click
      return if @clickables.empty?

      @mouse_point = $gtk.args.inputs.mouse.point
      process_scroll # Hanging this here for now.  It also needs @mouse_point

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
        # puts "Zif::InputService#process_click: clickable: #{clickable.class} #{clickable} -> #{clickable.rect}"

        clicked_sprite = clickable.clicked?(@mouse_point, kind)
        next unless clicked_sprite

        @expecting_mouse_up |= [clicked_sprite] if mouse_only_down
        break if @absorb_list.include? clickable

        # puts "Zif::InputService#process_click: #{@expecting_mouse_up.length} expecting"
        # puts "Zif::InputService#process_click: -> sprite handled click #{clicked_sprite}"
      end

      @expecting_mouse_up = [] if mouse_up
      @last_mouse_bits = mouse_bits
    end
    # rubocop:enable Metrics/PerceivedComplexity

    def process_scroll
      return if @scrollables.empty?

      wheel = $gtk.args.inputs.mouse.wheel
      return unless wheel

      wheel_direction = wheel.y.positive? ? :up : :down

      @scrollables.each do |scrollable|
        scrollable.scrolled?(@mouse_point, wheel_direction)
      end
    end
  end
end
