module Zif
  module Services
    # This service keeps track of sprites and other objects interested in responding to clicks and scroll events, and
    # passes the events over to them when they occur.
    #
    # Specifically, every tick {Zif::Game} will invoke {#process_click} on this service.
    #
    # In turn, this calls {Zif::Clickable#clicked?} on all {Zif::Clickable} objects which have been previously
    # registered using {#register_clickable}.
    #
    # It expects each clickable object to define a +#clicked?(point, kind)+ method.  If the sprite decides it has been
    # clicked, it should return itself from this method.  Clicks are passed through to sprites based on their +z_index+
    # value - if this value is nil, the service considers it to be at the bottom.
    #
    # {register_scrollable}, is analogous to {register_clickable} but for the scroll wheel. +#scrolled?+ is expected
    # to be defined, and it receives the mouse point and the direction of scrolling as arguments.  Only {Zif::Camera}
    # defines +#scrolled?+ out of the box.
    #
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
        @key_pressables = []
        @hoverables = []
      end

      # Add a {Zif::Clickable} object to the list of clickables to check every tick.
      # Clickables in this list are sorted by their +z_index+ and checked in *descending* order.
      # Clickable objects should respond to #clicked?(point, kind) and optionally #absorb_click?
      #
      # @param [Zif::Clickable] clickable A clickable object
      # @param [Boolean] absorb_click Should +clickable+ absorb clicks?
      #   If +clickable+ responds to +#absorb_click?+, this is true by default.
      def register_clickable(clickable, absorb_click: nil)
        @clickables << clickable
        @absorb_list << clickable if absorb_click || (clickable.respond_to?(:absorb_click?) && clickable.absorb_click?)
        @clickables.sort! do |a, b|
          next 1 unless a.respond_to?(:z_index)
          next -1 unless b.respond_to?(:z_index)

          b.z_index <=> a.z_index
        end
        clickable
      end

      # Removes an {Zif::Clickable} from the clickables array.
      # @param [Zif::Clickable] clickable
      def remove_clickable(clickable)
        @clickables.delete(clickable)
      end

      # Add a {Zif::Hoverable} object to the list of hoverables to check every tick.
      # Hoverable objects should respond to #hovered?(point)
      #
      # @param [Zif::Hoverable] hoverable A hoverable object
      def register_hoverable(hoverable)
        @hoverables << hoverable
        hoverable
      end

      # Removes an {Zif::Hoverable} from the hoverables array.
      # @param [Zif::Hoverable] hoverable
      def remove_hoverable(hoverable)
        @hoverables.delete(hoverable)
      end

      # Add a {Zif::KeyPressable} object to the list of keypressables to check every tick.
      # Keypressable objects should respond to handle_key(key, kind=:down)
      #
      # @param [Zif::KeyPressable] key_pressable A Keypressable object
      def register_key_pressable(key_pressable)
        @key_pressables << key_pressable
        key_pressable
      end

      # Removes an {Zif::KeyPressable} from the keypressables array.
      # @param [Zif::KeyPressable] key_pressable
      def remove_key_pressable(key_pressable)
        @key_pressables.delete(key_pressable)
      end

      # @todo Add Zif::Scrollable ?
      # Scrollable objects should respond to #scroll?(point, direction) and optionally #absorb_scroll?
      def register_scrollable(scrollable, absorb_scroll=nil)
        @scrollables << scrollable

        if absorb_scroll || (scrollable.respond_to?(:absorb_scroll?) && scrollable.absorb_scroll?)
          @absorb_list << scrollable
        end

        @scrollables.sort! do |a, b|
          next 1 unless a.respond_to?(:z_index)
          next -1 unless b.respond_to?(:z_index)

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
        process_hover

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
      def process_key_event
        return if @key_pressables.empty?

        text_keys = $gtk.args.inputs.text
        all_keys = $gtk.args.inputs.keyboard.key_down.truthy_keys

        text_keys << nil if text_keys.empty? && !all_keys.empty?

        text_keys.each do |key|
          @key_pressables.each do |key_pressable|
            # puts "Zif::Services::InputService#process_key_event:#{key} #{all_keys} key_pressable:#{key_pressable.class} #{key_pressable}"
            key_pressable.handle_key(key, all_keys)
          end
        end
        nil
      end

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

      # @api private
      def process_hover
        return if @hoverables.empty?

        @hoverables.each do |hoverable|
          hoverable.hovered?(@mouse_point)
        end
      end
    end
  end
end
