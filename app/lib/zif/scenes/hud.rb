module Zif
  # A standard place to put detached user interface / overlays for a particular Scene
  class Hud
    attr_accessor :scene, :primitives, :labels

    def initialize(scene)
      @scene = scene
      @primitives = []
      @labels = []
    end
  end
end
