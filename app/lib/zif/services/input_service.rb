module Zif
  module Services
    # This service keeps track of any clickable sprites that need to be informed of a click.
    #
    # Specifically, every tick {Zif::Game} will invoke {#process_click} on this service.
    #
    # In turn, this calls {Zif::Clickable#clicked?} on all {Zif::Clickable} objects which have been previously
    # registered using {#register_clickable}.
    # @see Zif::Clickable
    class InputService

      def initialize
        @last_mouse_bits = 0
        reset
      end

      # Resets the list of clickables, scrollables, etc.
      def reset
        @clickables = []
        @scrollables = []
        @absorb_list = []
        @expecting_mouse_up = []
      end

      # Add a {Zif::Clickable} object to the list of clickables to check every tick.
      # Clickables in this list are sorted by their +z_index+ and checked in *descending* order.
      # Clickable objects should respond to #clicked?(point, kind) and optionally #absorb_click?
      #
      # @param [Zif::Clickable] clickable A clickable object
      # @param [Boolean] absorb_click Should +clickable+ absorb clicks?
      #   If +clickable+ responds to +#absorb_click?+, this is true by default.
      def register_clickable(clickable, absorb_click=nil)
        @clickables << clickable
        @absorb_list << clickable if absorb_click || (clickable.respond_to?(:absorb_click?) && clickable.absorb_click?)
        @clickables.sort! do |a, b|
          next 1 unless a&.respond_to?(:z_index)
          next -1 unless b&.respond_to?(:z_index)

          b.z_index <=> a.z_index
        end
        clickable
      end

      # Removes an {Zif::Clickable} from the clickables array.
      # @param [Zif::Clickable] clickable
      def remove_clickable(clickable)
        @clickables.delete(clickable)
      end

      # @todo Add Zif::Scrollable ?
      # Scrollable objects should respond to #scroll?(point, direction) and optionally #absorb_scroll?
      def register_scrollable(scrollable, absorb_scroll=nil)
        @scrollables << scrollable

        if absorb_scroll || (scrollable.respond_to?(:absorb_scroll?) && scrollable.absorb_scroll?)
          @absorb_list << scrollable
        end

        @scrollables.sort! do |a, b|
          next 1 unless a&.respond_to?(:z_index)
          next -1 unless b&.respond_to?(:z_index)

          b.z_index <=> a.z_index
        end
        scrollable
      end

      # Removes a scrollable from the scrollables array.
      def remove_scrollable(scrollable)
        @scrollables.delete(scrollable)
      end

      # rubocop:disable Metrics/PerceivedComplexity
      # @api private
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

        # puts "Zif::Services::InputService#process_click: #{@mouse_point} point, #{mouse_bits} bits, kind: #{kind}."
        # puts "                                 #{awaiting_clicks.count} registered"

        awaiting_clicks.each do |clickable|
          # puts "Zif::Services::InputService#process_click: clickable: #{clickable.class} #{clickable} -> #{clickable.rect}"

          clicked_sprite = clickable.clicked?(@mouse_point, kind)
          next unless clicked_sprite

          @expecting_mouse_up |= [clicked_sprite] if mouse_only_down
          break if @absorb_list.include? clickable

          # puts "Zif::Services::InputService#process_click: #{@expecting_mouse_up.length} expecting"
          # puts "Zif::Services::InputService#process_click: -> sprite handled click #{clicked_sprite}"
        end

        @expecting_mouse_up = [] if mouse_up
        @last_mouse_bits = mouse_bits
      end
      # rubocop:enable Metrics/PerceivedComplexity

      # @api private
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
end
