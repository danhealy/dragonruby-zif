module Zif
  # For creating and updating Render Targets
  # References the render target in a @containing_sprite
  class RenderTarget
    include Zif::Serializable

    attr_accessor :name, :width, :height, :bg_color
    attr_accessor :sprites, :labels, :primitives

    def initialize(name, bg_color=:black, width=1, height=1)
      @name       = name
      @width      = width
      @height     = height
      @sprites    = []
      @labels     = []
      @primitives = []
      # This could probably be improved with a Color module
      @bg_color = case bg_color
                  when :black
                    [0, 0, 0, 0]
                  when :white
                    [255, 255, 255, 0]
                  else
                    bg_color
                  end
    end

    # Instantiate only when needed
    def containing_sprite
      return @containing_sprite if @containing_sprite

      redraw
      @containing_sprite = Zif::Sprite.new.tap do |s|
        s.name = "rt_#{@name}_containing_sprite"
        s.x = 0
        s.y = 0
        s.w = @width
        s.h = @height
        s.path = @name
        s.source_x = 0
        s.source_y = 0
        s.source_w = @width
        s.source_h = @height
        s.render_target = self
      end
    end

    def resize(w, h)
      @width = w
      @height = h
    end

    # By setting width and height, this actually recreates the render target in memory
    # This is the only way to force any changes to the RT.  You must call this any time you want to redraw @sprites, etc
    def redraw
      # puts "RenderTarget#redraw: #{@name} #{@width} #{@height} #{@sprites.length} sprites, #{@labels.length} labels"
      targ = $gtk.args.outputs[@name]
      targ.width  = @width
      targ.height = @height

      # It's important to set the background color intentionally.  Even if alpha == 0, semi-transparent images in
      # render targets will pick up this color as an additive.  Usually you want black.
      targ.background_color = @bg_color
      targ.primitives << @primitives if @primitives&.any?
      targ.sprites    << @sprites    if @sprites&.any?
      targ.labels     << @labels     if @labels&.any?
    end

    def clicked?(point, kind=:up)
      relative = relative_point(point)
      puts "#{self.class.name}:#{name}: clicked? #{point} -> relative #{relative}"

      find_and_return = ->(sprite) { sprite.respond_to?(:clicked?) && sprite.clicked?(relative, kind) }
      @sprites.reverse_each.find(&find_and_return) || @primitives.reverse_each.find(&find_and_return)
    end

    def relative_point(point)
      Zif.add_positions(Zif.sub_positions(point, containing_sprite.xy), containing_sprite.source_xy)
    end

    # Expects rect is x, y, w, h
    def project_to(rect={})
      containing_sprite.assign(
        containing_sprite.rect_hash.merge(rect)
      )
    end

    # Expects rect is x, y, w, h - not source_...
    def project_from(rect={})
      containing_sprite.assign(
        containing_sprite.source_rect_hash.merge(
          Zif::Sprite.rect_hash_to_source_hash(rect)
        )
      )
    end
  end
end
