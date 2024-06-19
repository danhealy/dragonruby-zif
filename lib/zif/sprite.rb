module Zif
  # A basic sprite which combines actions / animations, click handling, mass assignment and more.
  #
  # The foundation for most of the Zif library.
  #
  # Includes +attr_sprite+ -- supports what DRGTK provides for these classes in addition to what is documented here.
  #
  # See DRGTK docs on +attr_sprite+:
  # http://docs.dragonruby.org/#----attr_sprite.rb
  #
  # @example Basic usage
  #   dragon = Zif::Sprite.new.tap do |s|
  #     s.x = 300
  #     s.y = 300
  #     s.w = 82
  #     s.h = 66
  #     s.path = "sprites/dragon_1.png"
  #   end
  #   # At this point, you can render your dragon:
  #   $gtk.args.outputs.sprites << dragon
  #
  # @example Scaling an image
  #   # dragon is the dragon sprite with path +sprites/dragon_1.png+.  This image is 82 pixels wide, 66 pixels tall.
  #
  #   # Place our sprite at 10,10 on the screen:
  #   dragon.x = 10
  #   dragon.y = 10
  #
  #   # The sprite should be 100 pixels by 100 pixels in size on the screen:
  #   dragon.w = 100
  #   dragon.h = 100
  #
  #   # Only show the center 50x50 pixels of the source image:
  #   dragon.source_w = 50
  #   dragon.source_h = 50
  #
  #   # Take that 50x50 slice from the center of the image
  #   dragon.source_x = 82.fdiv(2) - 25
  #   dragon.source_y = 66.fdiv(2) - 25
  #
  #   # All together, this means we are showing
  #   # - the center 50x50 pixels of the dragon,
  #   # - scaled up to fit 100x100,
  #   # - at 10,10 on the screen
  # @example Handling clicks
  #   # Building on dragon from the basic example.  Expects Zif::Services::InputService to be set up.
  #
  #  # This only needs to be done once globally, usually in your Zif::Scene#prepare_scene method
  #  $game.services[:input_service].register_clickable(dragon)
  #
  #   # Turn the dragon red when the mouse is clicked down.
  #   # This lambda is called by the input service with this sprite (dragon) plus the mouse location.
  #   # We don't need the mouse location for this example so we prefix that argument with _ to indicate it is unused
  #   dragon.on_mouse_down = lambda {|sprite, _point|
  #     sprite.r = 255
  #     sprite.g = 0
  #     sprite.b = 0
  #   }
  #
  #   # Turn the dragon green when the mouse is clicked down & moved
  #   dragon.on_mouse_changed = lambda {|sprite, _point|
  #     sprite.r = 0
  #     sprite.g = 255
  #     sprite.b = 0
  #   }
  #
  #   # Turn the dragon blue when the mouse click ends - the dragon stays blue after this until you click again.
  #   dragon.on_mouse_up = lambda {|sprite, _point|
  #     sprite.r = 0
  #     sprite.g = 0
  #     sprite.b = 255
  #   }
  class Sprite
    include Zif::Assignable
    include Zif::Serializable
    include Zif::Actions::Actionable
    include Zif::Actions::Animatable
    include Zif::Clickable
    attr_sprite

    BLENDMODE = {
      none:     0,
      alpha:    1,
      add:      2,
      mod:      3,
      multiply: 4
    }.freeze

    # @return [Symbol, String] The name of this instance.  This helps differentiate multiple copies when debugging.
    attr_accessor :name

    # @return [Integer] Used for unit positioning (tile map addressing, for example - See {Zif::Layers::LayerGroup})
    attr_accessor :logical_x

    # @return [Integer] Used for unit positioning (tile map addressing, for example - See {Zif::Layers::LayerGroup})
    attr_accessor :logical_y

    # @note {Zif::Layers::LayerGroup} has it's own stacking order, each layer has a z-index.  Sprites contained within
    #   a layer are ordered amongst themselves using this attribute, but are constrained to the layer they are on.
    # @see Zif::Layers::LayerGroup#add_layer
    # @see Zif::Services::InputService#register_clickable
    # @return [Integer] Stacking order, used to determine which sprite is above another if overlapping.
    attr_accessor :z_index

    # If this sprite is a parent *container* for a {Zif::RenderTarget} (sources it via {path}), reference it here
    #
    # Not for sprites which are *children* (rendered inside) of a Render Target!
    # @return [Zif::RenderTarget] The render target this sprite references, like {Zif::RenderTarget#containing_sprite}
    attr_accessor :render_target

    # @!attribute [rw] x
    #   @return [Numeric] X axis position
    # @!attribute [rw] y
    #   @return [Numeric] Y axis position
    # @!attribute [rw] w
    #   @return [Numeric] Width
    # @!attribute [rw] h
    #   @return [Numeric] Height
    # @note The {source_x}, {source_y}, {source_w}, {source_h} attributes define the extent of the {path} image to show.
    #   Think of this as a dynamic crop of the image.  If source_x and source_y are +0,0+ and source_w, source_h are the
    #   same as the width and height of the image, the entire image is projected into this sprite.
    # @!attribute [rw] source_x
    #   @return [Numeric] X axis position of the {path} image we want to start sourcing the image from
    # @!attribute [rw] source_y
    #   @return [Numeric] Y axis position of the {path} image we want to start sourcing the image from
    # @!attribute [rw] source_w
    #   @return [Numeric] The X axis extent to which we will source the {path} image
    # @!attribute [rw] source_h
    #   @return [Numeric] The Y axis extent to which we will source the {path} image
    # @!attribute [rw] a
    #   @return [Numeric] Alpha channel (Transparency) (+0-255+)
    # @!attribute [rw] r
    #   @return [Numeric] Red color (+0-255+)
    # @!attribute [rw] g
    #   @return [Numeric] Green color (+0-255+)
    # @!attribute [rw] b
    #   @return [Numeric] Blue color (+0-255+)
    # @!attribute [rw] angle
    #   @return [Numeric] Rotation angle in degrees
    # @!attribute [rw] path
    #   @return [Symbol, String] The source of this image.
    #     Either the path to the image file relative to +app/+, or the name of the render target.

    # @param [Symbol, String] name {name}
    def initialize(name=Zif.unique_name('sprite'))
      @name      = name
      @logical_x = 0
      @logical_y = 0
      @x         = 0
      @y         = 0
      @z_index   = 0
      @w         = 0
      @h         = 0
      @a         = 255
      @r         = 255
      @g         = 255
      @b         = 255
      @angle     = 0
      self.blend = :alpha
    end

    # @param [Hash<Symbol, Object>] sprite A hash of key-values to mass assign to a copy of this sprite.
    # @see Zif::Assignable
    # @return [Zif::Sprite] A copy of this sprite, with the changes applied.
    def dup_and_assign(sprite)
      dup.assign(sprite)
    end

    # Set blend mode using either symbol names or the enum integer values.
    # @param [Symbol, Integer] new_blendmode {blend} +:none+, +:alpha+, +:add+, +:mod+, +:multiply+ or +0+, +1+, +2+, +3+, +4+. See {BLENDMODE}
    # @return [Integer] The integer value for the specified blend mode
    def blend=(new_blendmode)
      @blendmode = BLENDMODE.fetch(new_blendmode, new_blendmode)
    end

    alias blendmode_enum= blend=

    # @return [Integer] The integer value for the specified blend mode.  See {BLENDMODE}
    # @example This always returns an integer, even if you set it using a symbol
    #   mysprite.blend = :alpha  # => 1
    #   mysprite.blend           # => 1
    def blend
      @blendmode
    end

    alias blendmode_enum blend

    # Sets {a} alpha to 255 (fully opaque)
    def show
      @a = 255
    end

    # @note Some processing may be skipped if this sprite is hidden, to increase performance.
    # @see Zif::CompoundSprite#draw_override
    # Sets {a} alpha to 0 (fully transparent).
    def hide
      @a = 0
    end

    # @see Zif::Clickable#clicked?
    # @param [Array<Integer>] point [x, y] position Array of the current mouse click.
    # @param [Symbol] kind The kind of click coming through, one of [:up, :down, :changed]
    # @return [Object, nil]
    #   If this sprite has a {render_target}, pass the click through to it.
    #   Otherwise, call {Zif::Clickable#clicked?} and return this sprite or +nil+.
    def clicked?(point, kind=:up)
      return super(point, kind) unless @render_target && !absorb_click?

      @render_target.clicked?(point, kind)
    end

    # @param [Array<Numeric>] arr Takes an array of +[x, y, w, h]+ integers
    # @return [Hash<Symbol, Numeric>] Converts the array into a hash with those values mapped like +{x: ... }+
    def self.rect_array_to_hash(arr=[])
      {
        x: arr[0],
        y: arr[1],
        w: arr[2],
        h: arr[3]
      }
    end

    # @param [Array<Numeric>] arr Takes an array of +[source_x, source_y, source_w, source_h]+ integers
    # @return [Hash<Symbol, Numeric>] Converts the array into a hash with those values mapped like +{source_x: ... }+
    def self.rect_array_to_source_hash(arr=[])
      {
        source_x: arr[0],
        source_y: arr[1],
        source_w: arr[2],
        source_h: arr[3]
      }
    end

    # @param [Hash<Symbol, Numeric>] rect +{x: ..., y: ...}+
    # @return [Hash<Symbol, Numeric>] Converts keys in +rect+ like +{source_x: ..., source_y: ...}+
    def self.rect_hash_to_source_hash(rect={})
      rect.transform_keys { |key| key.include?('source_') ? key : "source_#{key}".to_sym }
    end

    # @return [Array<Numeric>] [{x}, {y}]
    def xy
      [@x, @y]
    end

    # @return [Array<Numeric>] [{w}, {h}]
    def wh
      [@w, @h]
    end

    # @return [Integer] The +x+ value of center point of the sprite (calculated from {x} and {w})
    def center_x
      (@x + @w.idiv(2)).to_i
    end

    # @return [Integer] The +y+ value of center point of the sprite (calculated from {y} and {h})
    def center_y
      (@y + @h.idiv(2)).to_i
    end

    # @return [Array<Numeric>] [{center_x}, {center_y}]
    def center
      [center_x, center_y]
    end

    # @note Performance Tip: Use the Sprite itself for things like +#intersect_rect?+ rather than creating this array!
    # @return [Array<Numeric>] [{x}, {y}, {w}, {h}]
    def rect
      [@x, @y, @w, @h]
    end

    # @return [Hash<Symbol, Numeric>] x: {x}, y: {y}, w: {w}, h: {h}
    def rect_hash
      Sprite.rect_array_to_hash(rect)
    end

    # This sets all of {source_x}, {source_y}, {source_w}, {source_h} to display the entire width and height
    # You want to use this, unless you're trying to zoom/pan.
    # These attrs need to be set before we can display component sprites.
    def view_actual_size!
      @source_x = 0
      @source_y = 0
      @source_w = @w
      @source_h = @h
    end

    # @return [Boolean] True if {source_x}, {source_y}, {source_w}, {source_h} are all set to something
    def source_is_set?
      !(@source_x.nil? || @source_y.nil? || @source_w.nil? || @source_h.nil?)
    end

    # @return [Array<Numeric>] [{source_x}, {source_y}]
    def source_xy
      [@source_x, @source_y]
    end

    # @return [Array<Numeric>] [{source_w}, {source_h}]
    def source_wh
      [@source_w, @source_h]
    end

    # @return [Array<Numeric>] [{source_x}, {source_y}, {source_w}, {source_h}]
    def source_rect
      [@source_x, @source_y, @source_w, @source_h]
    end

    # @return [Array<Numeric>] [source center x, source center y]
    def source_center
      [(@source_x + @source_w.idiv(2)).to_i, (@source_y + @source_h.idiv(2)).to_i]
    end

    # @return [Array<Numeric>] [{w} divided by {source_w}, {h} divided by {source_h}]
    def zoom_factor
      [@w.fdiv(@source_w), @h.fdiv(@source_h)]
    end

    # @return [Hash<Symbol, Numeric>] source_x: {source_x}, source_y: {source_y}, source_w: {source_w}, source_h: {source_h}
    def source_rect_hash
      Sprite.rect_array_to_source_hash(source_rect)
    end

    # If for some reason you want +source_+ attrs without +"source_"+ keys
    # @return [Hash<Symbol, Numeric>] x: {source_x}, y: {source_y}, w: {source_w}, h: {source_h}
    def source_as_rect_hash
      Sprite.rect_array_to_hash(source_rect)
    end

    # @return [Hash<Symbol, Numeric>] r: {r}, g: {g}, b: {b}, a: {a}
    def color
      {
        r: @r,
        g: @g,
        b: @b,
        a: @a
      }
    end

    # @note Use +#assign+ if you want to assign with a hash.  This works with positional array.
    # @param [Array<Numeric>] rgba_array +[r, g, b, a]+.  If any entry is nil, assignment is skipped.
    def color=(rgba_array=[])
      @r = rgba_array[0] if rgba_array[0]
      @g = rgba_array[1] if rgba_array[1]
      @b = rgba_array[2] if rgba_array[2]
      @a = rgba_array[3] if rgba_array[3]
    end

    # @return [Hash<Symbol, Numeric>] Hash of {color} + {rect_hash} + {source_rect_hash} + {path}
    def to_h
      {path: @path}.merge(source_rect_hash).merge(rect_hash).merge(color)
    end

    # @api private
    def exclude_from_serialize
      %w[render_target]
    end
  end
end
