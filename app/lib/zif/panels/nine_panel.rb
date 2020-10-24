module Zif
  # For setting up a 9-slice panel/window
  class NinePanel < ComplexSprite
    attr_accessor :corners, :edges, :fill, :labels

    # Draw 4 corners,
    # 4 edges (with optional transition),
    # then fill the center
    def initialize(target_name)
      super(target_name)
      @corners = Array.new(4) # ul, ur, ll, lr
      @edges = Array.new(4) # upper, right, lower, left
      @labels = []
      @min_height = 4
      @min_width = 4
    end

    def redraw
      # It's important that the fill is drawn first so it can overlap the other components (See MetalCutout)
      @render_target.sprites = [@fill] + @edges + @corners
      @render_target.labels = @labels
      draw_target
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
