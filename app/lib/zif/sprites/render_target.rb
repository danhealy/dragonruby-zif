module Zif
  # For creating and updating Render Targets
  # References the render target in a @containing_sprite
  class RenderTarget
    include Zif::Serializable

    attr_accessor :name, :width, :height, :bg_color
    attr_accessor :sprites, :labels, :primitives, :z

    def initialize(name, bg_color=:black, width=1, height=1, z=0)
      @name       = name
      @width      = width
      @height     = height
      @z          = z
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
        s.z = @z
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
      # $services&.named(:tracer)&..mark("#redraw: #{@name} Begin")
      targ = $gtk.args.outputs[@name]
      targ.width  = @width
      targ.height = @height

      # It's important to set the background color intentionally.  Even if alpha == 0, semi-transparent images in
      # render targets will pick up this color as an additive.  Usually you want black.
      targ.background_color = @bg_color
      targ.primitives << @primitives if @primitives&.any?
      targ.sprites    << @sprites    if @sprites&.any?
      targ.labels     << @labels     if @labels&.any?
      # $services&.named(:tracer)&..mark("#redraw: #{@name} Complete")
    end

    def clicked?(point, kind=:up)
      relative = relative_point(point)
      # puts "#{self.class.name}:#{name}: clicked? #{point} -> relative #{relative}"

      find_and_return = ->(sprite) { sprite.respond_to?(:clicked?) && sprite.clicked?(relative, kind) }
      @sprites.reverse_each.find(&find_and_return) || @primitives.reverse_each.find(&find_and_return)
    end

    def relative_point(point)
      Zif.add_positions(
        Zif.sub_positions(
          point, # FIXME??: Zif.position_math(:mult, point, containing_sprite.source_wh),
          containing_sprite.xy
        ),
        containing_sprite.source_xy
      )
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

    def exclude_from_serialize
      %w[sprites primitives]
    end

    # ----------------
    # Double Buffering
    #
    # These are methods are for drawing new sprites on top of an already rendered RT, and optionally cut out a rectangle
    # from the RT (for deletion)
    # You might want to use this if your list of @sprites for the RT is very large, so rendering all of the sprites is
    # slow, and you just need to modify a small subset.
    #
    # The classic example is a paint application, where each tick adds a new brush stroke to the canvas.
    # Instead of letting the @sprites array grow unbounded and redrawing all of them for each stroke, simply take the
    # previous canvas and draw a new sprite on top of it.
    #
    # A more complex example is if a single tile is changing inside of a large tile map.
    # Instead of redrawing every tile, delete the tile which is changing from the already rendered target, and then
    # redraw just the changing tile.
    #
    # So one drawback of using this is that you are forced to specify a single rectangle area which is changing.
    #
    # Another drawback to using this is that the @path for any sprite referencing the RenderTarget needs to change
    # every time the buffer is switched.  Since this references it's own containing sprite, we can update the
    # path for that sprite automatically, but if there exist any additional sprites referencing the @path (like if you
    # have a map and a minimap pointing to the same path), those will have to be updated manually.
    # To support this, you can pass additional sprites as an array to #switch_buffer.
    def set_inactive_buffer_name
      @inactive_buffer_name = "#{@name}_buf"
    end

    def switch_buffer(additional_containing_sprites=[])
      ([containing_sprite] + additional_containing_sprites).each { |cs| cs.path = @inactive_buffer_name }
      @inactive_buffer_name, @name = @name, @inactive_buffer_name
    end

    def redraw_from_buffer(sprites=[], cut_rect=nil, additional_containing_sprites=[])
      # $services&.named(:tracer)&..mark("RenderTarget#redraw_from_buffer: #{@name} Begin")
      source_buffer_sprites = cut_rect ? cut_containing_sprites(cut_rect) : [full_containing_sprite]

      set_inactive_buffer_name unless @inactive_buffer_name
      # puts "RenderTarget#redraw_from_buffer: name: #{@name}, inactive: #{@inactive_buffer_name}"
      # puts "RenderTarget#redraw_from_buffer: cut_rect: #{cut_rect}, source: #{source_buffer_sprites.inspect}"

      # $services&.named(:tracer)&..mark("RenderTarget#redraw_from_buffer: #{@name} Sprites")
      targ = $gtk.args.outputs[@inactive_buffer_name]
      targ.width  = @width
      targ.height = @height
      # $services&.named(:tracer)&..mark("RenderTarget#redraw_from_buffer: #{@name} HW")
      targ.background_color = @bg_color
      targ.sprites << [source_buffer_sprites] + sprites

      switch_buffer(additional_containing_sprites)
      # $services&.named(:tracer)&..mark("RenderTarget#redraw_from_buffer: #{@name} End")
    end

    # Expects xywh
    #                 right
    #                   v
    # @height -> +------+---+
    #            |   2  |   |
    #            |      | 3 |
    #     top -> +----+-+   |
    #            |    |r|   |
    #            | 1  +-+---+ <- bottom
    #            |    |  4  |
    #            |    |     |
    #     0,0 -> +----+-----+
    #                 ^     ^
    #                left   @width
    def cut_containing_sprites(rect)
      left   = rect[0]
      bottom = rect[1]
      right  = left + rect[2]
      top    = bottom + rect[3]

      [
        # 1
        {
          x:        0,
          source_x: 0,
          y:        0,
          source_y: 0,
          w:        left,
          source_w: left,
          h:        top,
          source_h: top,
          path:     @name
        },
        # 2
        {
          x:        0,
          source_x: 0,
          y:        top,
          source_y: top,
          w:        right,
          source_w: right,
          h:        @height - top,
          source_h: @height - top,
          path:     @name
        },
        # 3
        {
          x:        right,
          source_x: right,
          y:        bottom,
          source_y: bottom,
          w:        @width - right,
          source_w: @width - right,
          h:        @height - bottom,
          source_h: @height - bottom,
          path:     @name
        },
        # 4
        {
          x:        left,
          source_x: left,
          y:        0,
          source_y: 0,
          w:        @width - left,
          source_w: @width - left,
          h:        bottom,
          source_h: bottom,
          path:     @name
        }
      ]
    end

    def full_containing_sprite
      return @full_containing_sprite if @full_containing_sprite

      @full_containing_sprite = Zif::Sprite.new.tap do |s|
        s.name = "rt_#{@name}_full_containing_sprite"
        s.x = 0
        s.y = 0
        s.z = @z
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
  end
end
