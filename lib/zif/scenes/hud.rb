module Zif
  # A standard place to put detached user interface / overlays for a particular Scene
  # TODO: needs more implementation
  class Hud
    attr_accessor :scene, :render_target, :target_name

    def initialize(scene, target_name=nil)
      @scene = scene
      @target_name = target_name || "#{@scene.target_name}_hud"
      @render_target = Zif::RenderTarget.new(@target_name)
    end
  end
end
