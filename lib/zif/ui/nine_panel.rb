module Zif
  module UI
    # A 9-slice panel/window
    #
    # It is able to have multiple sprites because it inherits from {Zif::CompoundSprite}.
    #
    # @abstract Subclass and override at least {#resize_width} and {#resize_height} to behave in a way which makes sense
    #   for your specific assets.  Suggested to override {#initialize} and call +super+ before setting +@corners+
    #   +@edges+ and +@fill+ to reasonable defaults for the assets you are using.
    #
    # See below for subclassing examples such as {ExampleApp::GlassPanel}
    class NinePanel < CompoundSprite
      # @return [Array<Zif::Sprite>] The corner slices in this order: +[upper_left, upper_right, lower_left, lower_right]+
      attr_accessor :corners
      # @return [Array<Zif::Sprite>] The edge slices in this order: +[upper, right, lower, left]+
      attr_accessor :edges
      # @return [Zif::Sprite] The center sprite
      attr_accessor :fill

      # ------------------
      # @!group 1. Public Interface

      # Draw 4 corners,
      # 4 edges (with optional transition),
      # then fill the center
      # @param [String] name The name of the nine panel, used for debugging
      def initialize(name=Zif.unique_name('nine_panel'))
        super(name)
        @corners = Array.new(4) # ul, ur, ll, lr
        @edges = Array.new(4) # upper, right, lower, left
      end

      # A convenience for setting both width and height.
      # @param [Integer] width Sets width to this value via {resize_width}
      # @param [Integer] height Sets height to this value via {resize_height}
      def resize(width, height)
        resize_width(width)
        resize_height(height)
        view_actual_size!
      end

      # In your subclass, please redefine this method so that it can be scaled properly
      # @see #width=
      def resize_width(_width)
        raise "#{self.class.name} is expected to define #resize_width, to properly set component sprite attributes"
      end

      # In your subclass, please redefine this method so that it can be scaled properly
      # @see #width=
      def resize_height(_height)
        raise "#{self.class.name} is expected to define #resize_height, to properly set component sprite attributes"
      end

      # This class has special getters and setters for +width+ and +height+.
      # The reason is that it's using {resize_width} and {resize_height} internally to support rescaling of the panel.
      # This allows you to change the width and height using a {Zif::Actions::Action} as this is already an
      # {Zif::Actions::Actionable} via {Zif::CompoundSprite} inheritance.
      # @param [Integer] new_width Sets width to this value via {resize_width}
      def width=(new_width)
        resize_width(new_width)
      end

      # @return [Integer] width
      def width
        @w
      end

      # @see #width=
      # @param [Integer] new_height Sets height to this value via {resize_height}
      def height=(new_height)
        resize_height(new_height)
      end

      # @return [Integer] height
      def height
        @h
      end

      # -------------------
      # Some accessor sugar

      # @!method upper_left_corner
      #   @return [Zif::Sprite] The specified corner.  Grabs the correct element from {corners}.
      # @!method upper_right_corner
      #   @return [Zif::Sprite] The specified corner.  Grabs the correct element from {corners}.
      # @!method lower_right_corner
      #   @return [Zif::Sprite] The specified corner.  Grabs the correct element from {corners}.
      # @!method lower_left_corner
      #   @return [Zif::Sprite] The specified corner.  Grabs the correct element from {corners}.
      # @!method upper_left_corner=(new_corner)
      #   @param [Zif::Sprite] new_corner Sets the specified corner to this.  Sets the correct element from {corners}.
      # @!method upper_right_corner=(new_corner)
      #   @param [Zif::Sprite] new_corner Sets the specified corner to this.  Sets the correct element from {corners}.
      # @!method lower_right_corner=(new_corner)
      #   @param [Zif::Sprite] new_corner Sets the specified corner to this.  Sets the correct element from {corners}.
      # @!method lower_left_corner=(new_corner)
      #   @param [Zif::Sprite] new_corner Sets the specified corner to this.  Sets the correct element from {corners}.

      %i[upper_left upper_right lower_right lower_left].each_with_index do |name, idx|
        define_method("#{name}_corner") { @corners[idx] }
        define_method("#{name}_corner=") { |new_corner| @corners[idx] = new_corner }
      end

      # @!method upper_left_edge
      #   @return [Zif::Sprite] The specified edge.  Grabs the correct element from {edges}.
      # @!method upper_right_edge
      #   @return [Zif::Sprite] The specified edge.  Grabs the correct element from {edges}.
      # @!method lower_right_edge
      #   @return [Zif::Sprite] The specified edge.  Grabs the correct element from {edges}.
      # @!method lower_left_edge
      #   @return [Zif::Sprite] The specified edge.  Grabs the correct element from {edges}.
      # @!method upper_left_edge=(new_edge)
      #   @param [Zif::Sprite] new_edge Sets the specified edge to this.  Sets the correct element from {edges}.
      # @!method upper_right_edge=(new_edge)
      #   @param [Zif::Sprite] new_edge Sets the specified edge to this.  Sets the correct element from {edges}.
      # @!method lower_right_edge=(new_edge)
      #   @param [Zif::Sprite] new_edge Sets the specified edge to this.  Sets the correct element from {edges}.
      # @!method lower_left_edge=(new_edge)
      #   @param [Zif::Sprite] new_edge Sets the specified edge to this.  Sets the correct element from {edges}.

      %i[upper right lower left].each_with_index do |name, idx|
        define_method("#{name}_edge") { @edges[idx] }
        define_method("#{name}_edge=") { |new_edge| @edges[idx] = new_edge }
      end

      # ------------------
      # @!group 2. Private-ish methods

      # This is an override to allow {Zif::CompoundSprite} to work with the three separate arrays
      # @api private
      # @return [Array<Zif::Sprite>] An array of all of the sprites for the nine panel: {corners} {edges} and {fill}
      def sprites
        unless @sprites_assigned
          @sprites.unshift(
            @fill,
            *@edges,
            *@corners
          )
          @sprites.flatten!
          @sprites_assigned = true
        end

        @sprites
      end
    end
  end
end
