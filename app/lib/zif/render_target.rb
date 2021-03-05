module Zif
  # For creating and updating Render Targets.
  #
  # A render target in DRGTK is a way to programmatically create a static image out of sprites.  It acts just like
  # +$gtk.args.outputs+ in that it accepts an array of +sprites+ and other +primitives+.  It gets rendered into memory
  # at the end of the tick where it is referenced out of +$gtk.args.outputs[...]+, based on its contents.  To display
  # the result, you need to send +$gtk.args.outputs+ a sprite which references the name of the render target as its
  # +path+.
  #
  # This class holds references to the {sprites} and all of the configuration options necessary to invoke this concept
  # in DragonRuby GTK.  It also includes a {Zif::Sprite} referencing the created image in {containing_sprite}.
  #
  # Once set up, you can force DRGTK to fully render the image using {#redraw}, which redraws everything.
  #
  # Although an already rendered RenderTarget is cheap to display, one drawback of using RenderTargets is that they take
  # a little longer to process in the first place, compared to simply drawing sprites the normal way.  This can become
  # an issue if you need to frequently update the RenderTarget due to changes on the source sprites.  Say you have a
  # large tile map you pregenerate as a RenderTarget when the game loads.  If you need to change a single tile, like if
  # that tile represents a door and the door opens, normally you would need to regenerate the entire RenderTarget using
  # all of the source sprites.
  #
  # A technique the DragonRuby community (specifically Islacrusez, oeloeloel) has identified to overcome this
  # performance issue is to build another RenderTarget using the previously rendered one, plus whatever sprites are
  # changing.  See this example implementation of this technique: https://github.com/oeloeloel/persistent-outputs
  #
  # This strategy is implemented here by {#redraw_from_buffer}.  Since this is inherently an additive process,
  # {#redraw_from_buffer} allows you to cut out a single rectangle (via the +cut_rect+ param) from the old image to
  # handle deletions.
  #
  # See DRGTK docs on Render Targets
  # http://docs.dragonruby.org/#----advanced-rendering---simple-render-targets---main.rb
  # @example Setting up a basic paint canvas
  #   paint_canvas = Zif::RenderTarget.new(:my_paint_canvas, bg_color: :white, width: 1000, height: 500)
  #   paint_canvas.sprites << @all_current_brushstrokes
  #   paint_canvas.redraw
  #   $gtk.args.outputs.static_sprites << paint_canvas.containing_sprite
  #
  #   # Some time later, you can add new brush strokes and delete a rectangle:
  #
  #   minimap = # ... a different sprite referencing the RenderTarget as path
  #   new_brushstroke = # ... a new Sprite to add to the render
  #   erase_rect = [200, 200, 10, 10] # Let's say you erased something, too
  #   paint_canvas.redraw_from_buffer([new_brushstroke], erase_rect, [minimap])
  class RenderTarget
    include Zif::Serializable

    # @return [String, Symbol]
    #   The name of the render target.  This is used when invoking the render target in DRGTK, so this must be unique.
    attr_accessor :name

    # @return [Integer] The total width of the rendered image.
    #   This could be larger or smaller than the size used to display the image on the {containing_sprite}.
    attr_accessor :width

    # @return [Integer] The total height of the rendered image.
    #   This could be larger or smaller than the size used to display the image on the {containing_sprite}.
    attr_accessor :height

    # @return [Symbol, Array<Integer>] Accepts +:black+, +:white+, or an RGBA color array like +[255,255,255,255]+
    attr_accessor :bg_color

    # @return [Array<Zif::Sprite>] The list of sprites this RenderTarget is rendering.
    attr_accessor :sprites

    # @return [Array<Zif::UI::Label>] The list of labels this RenderTarget is rendering.
    attr_accessor :labels

    # @return [Array<Zif::Sprite, Hash>] The list of other primitives this RenderTarget is rendering.
    attr_accessor :primitives

    # @return [Integer] When comparing the containing sprite with other sprites, this sets the layering order.
    attr_accessor :z_index

    # ------------------
    # @!group 1. Public Interface

    # @param [Symbol, String] name {name}
    # @param [Symbol, Array<Integer>] bg_color {bg_color}
    # @param [Integer] width {width}
    # @param [Integer] height {height}
    # @param [Integer] z_index {z_index}
    def initialize(name, bg_color: :black, width: 1, height: 1, z_index: 0)
      @name       = name
      @width      = width
      @height     = height
      @z_index    = z_index
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

    # @return [Zif::Sprite]
    #   A sprite which references this render target as its +path+, and set to the same +width+ and +height+ by default
    def containing_sprite
      return @containing_sprite if @containing_sprite

      redraw
      @containing_sprite = Zif::Sprite.new.tap do |s|
        s.name = "rt_#{@name}_containing_sprite"
        s.x = 0
        s.y = 0
        s.z_index = @z_index
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

    # @param [Integer] w Change width
    # @param [Integer] h Change height
    def resize(w, h)
      @width = w
      @height = h
    end

    # Call this method when you want to actually draw all {sprites} onto the rendered image.
    # You will need to redraw if you want any changes made to {sprites} to be reflected in the {containing_sprite}.
    # This works by asking DRGTK for a reference to the render target by name, and resetting the {width} and {height}.
    # DRGTK detects this and performs the render at the end of the tick.
    # Therefore, please do not attempt to reference this render target directly via +$gtk.args+ outside of this class -
    # it will cause the render target to be redrawn without directing it to draw the sprites contained here.
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

    # This implements functionality for the {Zif::Services::InputService} to check for click handlers amongst the
    # list of {sprites} and {primitives} assigned to this object.
    # It will adjust the +point+ from the screen itself to the relative position of the {sprites} within the
    # {containing_sprite}, and send this adjusted point to the {sprites} +#clicked?+ method.
    # @see Zif::Clickable#clicked?
    # @param [Array<Integer>] point [x, y] position Array of the current mouse click.
    # @param [Symbol] kind The kind of click coming through, one of [:up, :down, :changed]
    # @return [Object, nil]
    #   If any {sprites} or {primitives} respond positively to being +#clicked?+ at the adjusted +point+, this returns
    #   the object which was clicked.
    #   Otherwise return +nil+.
    def clicked?(point, kind=:up)
      relative = relative_point(point)
      # puts "#{self.class.name}:#{name}: clicked? #{point} -> relative #{relative}"

      find_and_return = ->(sprite) { sprite.respond_to?(:clicked?) && sprite.clicked?(relative, kind) }
      @sprites.reverse_each.find(&find_and_return) || @primitives.reverse_each.find(&find_and_return)
    end

    # Convert the positional [x, y] array +point+ from the screen coordinates, to the relative coordinates inside the
    # {containing_sprite}
    # @param [Array<Integer>] point [x, y] position Array in the context of the screen
    # @return [Array<Integer>] point [x, y] position Array in the context of the {containing_sprite}
    def relative_point(point)
      Zif.add_positions(
        Zif.sub_positions(
          point, # FIXME??: Zif.position_math(:mult, point, containing_sprite.source_wh),
          containing_sprite.xy
        ),
        containing_sprite.source_xy
      )
    end

    # Reassigns the x, y, width and height of the {containing_sprite}.
    # @param [Hash<Symbol, Numeric>] rect A Hash containing +x+, +y+, +w+, +h+ keys and Numeric values.
    def project_to(rect={})
      containing_sprite.assign(
        containing_sprite.rect_hash.merge(rect)
      )
    end

    # Reassigns the +source_x+, +source_y+, +source_w+ and +source_h+ of the {containing_sprite}.
    # @param [Hash<Symbol, Numeric>] rect A Hash containing +x+, +y+, +w+, +h+ keys and Numeric values.
    def project_from(rect={})
      containing_sprite.assign(
        containing_sprite.source_rect_hash.merge(
          Zif::Sprite.rect_hash_to_source_hash(rect)
        )
      )
    end

    # @see Zif::Serializable#exclude_from_serialize
    def exclude_from_serialize
      %w[sprites primitives]
    end

    # Double Buffering
    #
    # This method is for drawing new sprites on top of an already rendered RT, and optionally cut out a rectangle
    # from the RT (for deletion)
    # You might want to use this if your list of {sprites} for the RT is very large, so rendering all of the sprites is
    # slow, and you just need to modify a small subset.
    #
    # The classic example is a paint application, where each tick adds a new brush stroke to the canvas.
    # Instead of letting the {sprites} array grow unbounded and redrawing all of them for each stroke, simply take the
    # previous canvas and draw a new sprite on top of it.
    #
    # A more complex example is if a single tile is changing inside of a large tile map.
    # Instead of redrawing every tile, delete the tile which is changing from the already rendered target, and then
    # redraw just the changing tile.
    #
    # One drawback of using this is that you are forced to specify a single rectangle area which is changing.
    #
    # Another drawback to using this is that the +path+ for any sprite referencing the RenderTarget needs to change
    # every time the buffer is switched.  Since this references it's own containing sprite, we can update the
    # path for that sprite automatically, but if there exist any additional sprites referencing the +path+ (like if you
    # have a map and a minimap pointing to the same +path+), those will have to be updated manually.
    # To support this, you can pass additional containing sprites as an array to have their +path+ updated.
    #
    # See the {ExampleApp::DoubleBufferRenderTest} scene for a working example.
    #
    # @todo Need some examples of double buffering
    # @param [Array<Zif::Sprite>] sprites Optional. An array of sprites to add to the image in this redraw.
    # @param [Array<Integer>] cut_rect Optional.  [x, y, w, h], the area to cut out from the existing buffer.
    # @param [Array<Zif::Sprite>] additional_containing_sprites
    #   Optional. An array of other containing sprites besides {containing_sprite} whose +path+ needs updating after
    #   switching buffers.
    def redraw_from_buffer(sprites: [], cut_rect: nil, additional_containing_sprites: [])
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

    # ----------------
    # @!group 2. Private-ish methods

    # @api private
    def set_inactive_buffer_name
      @inactive_buffer_name = "#{@name}_buf"
    end

    # Switch the {containing_sprite} (and optional additional containing sprites) +path+ to the inactive buffer
    # Swap names so the name is the inactive name and vice versa.
    # Private, you should probably not call this directly, it is called automatically by {redraw_from_buffer}
    # @param [Array<Zif::Sprite>] additional_containing_sprites An array of other containing sprites to update.
    # @api private
    def switch_buffer(additional_containing_sprites=[])
      ([containing_sprite] + additional_containing_sprites).each { |cs| cs.path = @inactive_buffer_name }
      @inactive_buffer_name, @name = @name, @inactive_buffer_name
    end

    #   .
    #                   right
    #                     v
    #   @height -> +------+---+
    #              |   2  |   |
    #              |      | 3 |
    #       top -> +----+-+   |
    #              |    |r|   |
    #              | 1  +-+---+ <- bottom
    #              |    |  4  |
    #              |    |     |
    #       0,0 -> +----+-----+
    #                   ^     ^
    #                  left   @width
    # This creates four sprite-hashes to capture the area outside of a rectangle, used in {redraw_from_buffer}
    # @param [Array<Integer>] rect +[x, y, w, h]+
    # @return [Array<Hash<Symbol, Numeric>>] four sprites around the rect
    # @api private
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

    # Like {containing_sprite}, returns a Zif::Sprite referencing {name} as +path+ at the full width.
    # This is private because it's used internally in {redraw_from_buffer}, it should not be modified externally
    # @api private
    def full_containing_sprite
      return @full_containing_sprite if @full_containing_sprite

      @full_containing_sprite = Zif::Sprite.new.tap do |s|
        s.name = "rt_#{@name}_full_containing_sprite"
        s.x = 0
        s.y = 0
        s.z_index = @z_index
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
