module Zif
  # For drawing several connected sprites as a single render_target
  # Handles instantiating render target and projecting the containing sprite to the full size of the render target
  # Clamps height and width based on maximums
  # TODO: Decide if this needs some refactor now that Zif::RenderTarget is doing most of the work
  class ComplexSprite
    # ID for the render_target, and the Zif::RenderTarget itself.
    attr_accessor :target_name, :render_target

    # Width and Height is the total extent of components.
    # Min width and Min height is the smallest possible total size.
    attr_accessor :width, :min_width, :height, :min_height

    def initialize(target_name)
      @target_name = target_name
      @render_target = RenderTarget.new(@target_name)
    end

    # Recalculate width and height based on minimums, then recreate the render target
    def resize(width, height)
      @width  = [width,  @min_width ].max
      @height = [height, @min_height].max
      # puts "ComplexSprite#resize: #{@width}w #{@height}h"
      draw_target
    end

    def draw_target
      # puts "ComplexSprite#draw_target: #{@target_name} #{@width}w #{@height}h"
      @render_target.resize(@width, @height)
      @render_target.redraw
      @render_target.project_to({w: @width, h: @height})
      @render_target.project_from({w: @width, h: @height})
      # puts "yup"
    end

    def rect
      @render_target.containing_sprite.rect
    end

    def containing_sprite(x=nil, y=nil)
      @render_target.containing_sprite.x = x if x
      @render_target.containing_sprite.y = y if y
      @render_target.containing_sprite
    end

    def clicked?(point, kind=:up)
      # puts "ComplexSprite#clicked? : #{point}"
      @render_target.containing_sprite.clicked?(point, kind)
    end
  end
end
