module Zif
  # For setting up a 9-slice panel/window
  class NinePanel < CompoundSprite
    attr_accessor :corners, :edges, :fill, :labels

    # Draw 4 corners,
    # 4 edges (with optional transition),
    # then fill the center
    def initialize(name=Zif.random_name('nine_panel'))
      super(name)
      @corners = Array.new(4) # ul, ur, ll, lr
      @edges = Array.new(4) # upper, right, lower, left
    end

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

    def resize(width, height)
      resize_width(width)
      resize_height(height)
      view_actual_size!
    end

    def resize_width(_width)
      raise "#{self.class.name} is expected to define #resize_width, to properly set component sprite attributes"
    end

    def resize_height(_height)
      raise "#{self.class.name} is expected to define #resize_height, to properly set component sprite attributes"
    end

    # Width methods to support actions
    def width=(new_width)
      resize_width(new_width)
    end

    def width
      @w
    end

    # Height methods to support actions
    def height=(new_height)
      resize_height(new_height)
    end

    def height
      @h
    end

    # -------------------
    # Some accessor sugar

    %i[upper_left upper_right lower_right lower_left].each_with_index do |name, idx|
      define_method("#{name}_corner") { @corners[idx] }
      define_method("#{name}_corner=") { |new_corner| @corners[idx] = new_corner }
    end

    %i[upper right lower left].each_with_index do |name, idx|
      define_method("#{name}_edge") { @edges[idx] }
      define_method("#{name}_edge=") { |new_edge| @edges[idx] = new_edge }
    end
  end
end
