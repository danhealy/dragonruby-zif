# Zif: A Drop-in Framework for DragonRuby GTK

Zif is a collection of features commonly required in 2D games.  The name is a reference to [Zero Insertion Force connectors used on the original Nintendo](https://console5.com/wiki/Improving_NES-001_Reliability) - You can drop it in your project and it should just work.  Everything is namespaced to `Zif` so any existing classes or namespaces you have should be preserved.


## Installation:
1. Create a `/ib` directory in the same directory as `app`, and then copy the `lib/zif` directory into it.
2. In your `main.rb`, require the Zif files in this order, before your code:

```ruby
require 'lib/zif/zif.rb'
require 'lib/zif/services/services.rb'
require 'lib/zif/sprites/assignable.rb'
require 'lib/zif/sprites/serializable.rb'
require 'lib/zif/actions/action.rb'
require 'lib/zif/actions/sequence.rb'
require 'lib/zif/actions/actionable.rb'
require 'lib/zif/sprites/sprite.rb'
require 'lib/zif/sprites/render_target.rb'
require 'lib/zif/sprites/complex_sprite.rb'
require 'lib/zif/services/sprite_registry.rb'
require 'lib/zif/services/action_service.rb'
require 'lib/zif/services/input_service.rb'
require 'lib/zif/labels/label.rb'
require 'lib/zif/components/two_stage_button.rb'
require 'lib/zif/panels/nine_panel_edge.rb'
require 'lib/zif/panels/nine_panel.rb'
require 'lib/zif/scenes/scene.rb'
require 'lib/zif/scenes/hud.rb'
require 'lib/zif/camera.rb'
require 'lib/zif/services/tick_trace_service.rb'
require 'lib/zif/trace/traceable.rb'
require 'lib/zif/layered_tile_map/simple_layer.rb'
require 'lib/zif/layered_tile_map/tiled_layer.rb'
require 'lib/zif/layered_tile_map/layered_tile_map.rb'
require 'lib/zif/game.rb'
```

# Features
## Module
### Zif
The `Zif` module itself has a collection of frequently used helpers, like `Zif.sub_positions` for subtracting one array with two elements (e.g. `[x, y]`) from another

## Mixins
These modules are designed to be included in another class.
- **`Zif::Serializable`**: Works with any class.  Automatically defines `#serialize` `#to_s` and `#inspect` based on the instance variables defined on the class. As you will encounter using DRGTK, if these methods are defined, DRGTK will use them to automatically print info to the console when exceptions occur.
- **`Zif::Actionable`**:  Works with any class.  Defines the required attributes & methods to allow this class to be used with the `ActionService`, namely `#run`, `#new_action`, `#stop_action` etc
- **`Zif::Assignable`**: Works with classes which implement sprite attributes (`Zif::Sprite` or any class with `attr_sprite`).  Allows you to `#assign` sprite attributes to the object with a hash, e.g. `obj.assign({x: 10, y: 10, w: 32...`
- **`Zif::Animatable`**: Works with classes which implement `#path` and `#path=`.  Helpers for generating `Sequence`s which change the `path` over time (animations).
- **`Zif::Traceable`**: Works with any class but expects `$services`.  Allows you to set a variable `@tracer_service_name` to the registered name of the `Zif::TickTraceService`, and afterwards you can simply use `#mark` to mark a section of code in this class for performance tracing.

## Basic Classes

### Zif::Sprite
This class is the basis for most of the framework.  It's a class which uses [`attr_sprite`](https://github.com/DragonRuby/dragonruby-game-toolkit-contrib/blob/master/dragon/attr_sprite.rb) and defines some basic helper methods: `#xy` returns an array `[@x, @y]`, and so on.  Includes all the mixins described above.  Additionally, it implements `#clicked?` - required for the `InputService`.

**Example usage**:
```ruby
@dragon = Zif::Sprite.new.tap do |s|
  s.x = 300
  s.y = 300
  s.w = 100
  s.h = 80
  s.path = "sprites/dragon_0.png"
end
```

### Zif::RenderTarget

A render target is a way to programmatically create a sprite.  It acts just like `$gtk.args.outputs` in that it accepts an array of `sprites` and other `primitives`.  It gets rendered on the tick where its `width` and `height` are defined (allocated).  To display it, you need to create a sprite and reference the name of the render target as the `path`.

This class handles this for you: it accepts `sprites` `labels` and `primitives` arrays.  You can force it to `#redraw`.  It produces a `#containing_sprite` which references itself, and you can use `#project_to` and `#project_from` to control panning and zooming.  It can be used with the `InputService` as it responds to `#clicked?` - and passes the click down to the component sprites and primitives.

**Example usage**:
```ruby
rt = Zif::RenderTarget.new(:a_dragon, :black, 100, 80)
rt.sprites << @dragon
$gtk.args.outputs.sprites << rt.containing_sprite(100, 100)
```

### Zif::Action
Inspried by [SpriteKit's Actions](https://developer.apple.com/documentation/spritekit/skaction) and [Squirrel Eiserloh's GDC talk on nonlinear transformations](https://www.youtube.com/watch?v=mr5xkf6zSzk).
An `Action` is a transition of a set of attributes over time using an easing function (aka tweening, easing).  On `#initialize` you define:
- an object to perform the action on (generally done for you via `#new_action` on `Zif::Actionable`)
- a `finish` state which is a hash of attributes and their desired final values
- a `duration` in ticks
- the `easing` function to use (see `Zif::Action::EASING_FUNCS`)
- the rounding function to use (`Zif::Action::ROUNDING_FUNCS`)
- the number of times to repeat the action, either an integer value or `:forever`
- Finally, it accepts a block to be used as a callback when the action finishes.

An `Actionable` can have several `Action`s running simultaneously.

**Example usage:**
```ruby
# @dragon is a Zif::Sprite and therefore an Actionable
# Move from starting position to 1000x over 1 second, starting slowly, then flip the sprite at the end
@dragon.run(@dragon.new_action({x: 1000}, 1.seconds, :smooth_start) { @dragon.flip_horizontally = true })
```

### Zif::Sequence
A `Sequence` is a series of `Actions` to be run in order.

**Example usage:**

```ruby
# Run some action sequences on this sprite
@dragon.run(@dragon.fade_out_and_in_forever)
@dragon.run(
  Zif::Sequence.new(
    [
      # Move from starting position to 1000x over 1 second, starting slowly, then flip the sprite at the end
      @dragon.new_action({x: 1000}, 1.seconds, :smooth_start) { @dragon.flip_horizontally = true },
      # Move from the new position (1000x) back to the start 600x over 2 seconds, stopping slowly, then flip again
      @dragon.new_action({x: 600}, 2.seconds, :smooth_stop) { @dragon.flip_horizontally = false }
    ],
    :forever
  )
)

@dragon.new_basic_animation(
  :fly,
  1.upto(4).map { |i| ["dragon_#{i}", 4] } + 3.downto(2).map { |i| ["dragon_#{i}", 4] }
)

@dragon.run_animation_sequence(:fly)
```
![](dragonruby-ui-sample.gif)

### Zif::Scene
A `Scene` is a full-screen view of your game.  The concept in `Zif::Game` is to show one `Scene` at a time. So each `Scene` in your game should be a subclass of `Zif::Scene` which overrides `#perform_tick`. Using the structure in `Zif::Game`, `#perform_tick` comes after input handling and before updating `Actionable`s. So your subclass should use `#perform_tick` to add/remove clickables/`Actionable`s, and respond to any detected input. Switching scenes is handled in `Zif::Game`, based on the return value of `#perform_tick`.  You can optionally define `#prepare_scene` - a method invoked prior to the first tick it is the active scene, and `#unload_scene` which is invoked after the Scene has been switched.

### Zif::Game
This is designed to be the base class for your game.  It's mainly responsible for Scene switching and yielding to `Scene#perform_tick` as described above, but also it automatically registers all the `Zif` services and provides standard functionality around this, including exception handling.

**Example usage:** in `main.rb`
```ruby
class MyGame < Zif::Game
  def initialize
    super()
    MyOneTime.setups # do anything here, like register services...
    register_scene(:rainbow_road, RainbowRoadScene) # (RainbowRoadScene is a Zif::Scene subclass)
    @scene = OpeningScene.new # (this is a Zif::Scene subclass)
  end
end

def tick(args)
  if args.tick_count == 2
    $game = MyGame.new
    $game.scene.prepare_scene # if needed on first scene
  end

  $game&.perform_tick
end
```

## Classes for 2D Scrolling Games
If your game's play area extends beyond the screen resolution, you likely want some way of

### Zif::LayeredTileMap

Creates a set of overlapping play area layers and handles redrawing them.

Has a concept of "logical" position as a multiple of "tile" width/height. (For example, if your tiles are `16px` wide, the 4th tile is at `@logical_x==4` but `@x==64`)

As an example, you can have a "tiles" layer which gets redrawn only at the start of the game, an "interactive
objects" layer which gets redrawn whenever objects appear or disappear, and then an "avatar" layer which gets
redrawn every time the avatar moves.  The advantage of using RenderTargets here is to keep the positioning
consistent across all of the layers.  You can just pass all of the RT containing sprites to `Zif::Camera` and it will
pan them all in unison.

You setup and configure these layers via `#new_simple_layer` and `#new_tiled_layer`.

Performance notes:
 - Since the memory requirements here are based on the number of layers * area of each layer, consider other
   approaches if you have a lot of layers with few sprites in them (maybe use sprites directly but with more math to
   keep positions in sync)
 - It is *expensive* to redraw a RT with thousands of sprites.  Consider - 1280x720 / 16x16 -> 80*45 = 3600 tiles.
   Of course it's more expensive to draw these every tick (not using render_target), but you will see noticable
   hiccups if you do this often.  Try not to redraw RTs with lots of sprites while action is happening.

**Example usage**:
```ruby
map_layer_render_target_prefix = "map"
tile_width_and_height = 64 # pixels
map_width_and_height_in_tiles = 100 # 64 * 100 = 6400x6400 pixels

@map = Zif::LayeredTileMap.new(
  map_layer_render_target_prefix,
  tile_width_and_height,
  tile_width_and_height,
  map_width_and_height_in_tiles,
  map_width_and_height_in_tiles
)
@map.new_tiled_layer(:tiles)
@map.new_simple_layer(:avatar)
@map.force_refresh # Force it to set up the render targets for the first time

# The should_render attribute will be checked each tick to decide if the RT should render
@map.layers[:avatar].should_render = true
@map.layers[:avatar].source_sprites = [@dragon]

# ----
# Add a bunch of tiles over a few ticks
a_new_tile = Zif::Sprite.new....
@map.add_positioned_sprite(x, y, a_new_tile)
# ----

# When all the tiles have been added
@map.layers[:tiles].should_render = true

@camera = Zif::Camera.new(
  @map.target_name,
  @map.layer_containing_sprites,
  Zif::Camera::DEFAULT_SCREEN_WIDTH,
  Zif::Camera::DEFAULT_SCREEN_HEIGHT,
  1800,
  1200
)

@map.refresh
@map.layers[:tiles].should_render = false # Really just want to render the tiles once.

$gtk.args.outputs.static_sprites << @camera.layers
```

### Zif::SimpleLayer

Designed to be used with `Zif::LayeredTileMap`, this is an extension of `RenderTarget` where `source_sprites` is a simple flat array.  Uses natural x/y positioning, and `visible_sprites` is a simple `select` of sprites which `intersect_rect?`.

### Zif::TiledLayer
A subclass of `SimpleLayer`, this redefines `source_sprites` as a 2-dimensional array, indexed by logical (tile) position.

### Zif::Camera
Designed to work with `Zif::LayeredTileMap`, the Camera is initialized with a set of layer sprites, typically these are the `containing_sprite`s of large render targets. It zooms these sprites to fit the viewable area of the screen. It is responsible for directing the layers to reposition based on camera movements.

The Camera is an example of an `Actionable` class which isn't a `Sprite`.  It defines `#pos_x` and `#pos_x=` methods to act like a single accessor for each layer's `source_x` values.  In this way, we can ease the panning of all the layers by creating an `Action` for a final `pos_x` value.

**Example usage:** (also see usage under `Zif::LayeredTileMap`)
```ruby
@camera.start_following(@dragon) if @dragon.walking
```

**TODO:** Camera could be extended to support parallax effects...

## Panels, Components, Labels
These are classes which help create UI elements.  TODO: More documentation.

## Services
Services are game features which can be accessed from any context within your game.  If you use `Zif::Game`, each service will be registered in the `Game`'s ivar `@services` by a symbol, e.g. `@services.register(:action_service, Zif::ActionService.new)` is run during initialization and thereafter you can access the `ActionService` by `game.services[:action_service]`.  Additionally by convention, both `$game` and `$services` are available as global variables.

### Zif::ActionService
Register your sprite as something to check for running `Action`s by using `#register_actionable`.  Call `#run_all_actions` once per tick (handled by `Zif::Game` automatically), which will invoke `#perform_actions` on each registered `@actionable`.

### Zif::InputService
On each tick, `#process_click` should be run, which will detect clicks and pass them on to each sprite which has been registered via `#register_clickable`.  It expects each clickable object to define a `#clicked?(point, kind)` method.  If the sprite decides it has been clicked, it should return itself from this method.

`Zif::Sprite` defines `#clicked?` and a set of ivars which are expected to contain callback lambdas: `@on_mouse_down, @on_mouse_up, @on_mouse_changed`.  If it can't handle the click but it knows it is the `containing_sprite` for a `Zif::RenderTarget`, it passes the click through.

`Zif::RenderTarget` also defines `#clicked?`, and passes clicks down to the component `@sprites` and `@primitives` of the render target.

`Zif::SimpleLayer` defines `#clicked?` and uses its `#visible_sprites` method to decide which component `@source_sprites` need to be checked for clicks.

### Zif::SpriteRegistry
This service allows you to register prototypes of assets as `Zif::Sprites`.

**Example usage:**

The following code will create a `Zif::Sprite` with w/h of 82px and 66px, referencing a `path` of `sprites/dragon_1.png`.  The second line demonstrates getting a fresh `Zif::Sprite` copy with these settings.
```ruby
$services[:sprite_registry].register_basic_sprite("dragon_1", 82, 66)
@dragon = $services[:sprite_registry].construct("dragon_1")
```


### Zif::TickTraceService
Generally, you want your game to run at a full 60fps.  If your tick takes longer than 16.6ms, you'll drop below that number.  The TickTrace service is designed to report when a tick has taken longer than a threshold (20ms by default), and hopefully narrow down the slowest section of code. `#reset_tick` must be called at the beginning of a tick, and then `#finish` at the end.  If you use `Zif::Game`, this is done for you, all you need to do is `include Traceable` in any class you want to mark, set the `@tracer_service_name` ivar to `:tracer`, and then `mark('a section of code')`.  Since backtraces are not supplied in DRGTK, the best it can do is tell you the name of the class it was invoked in.  By convention, you should include the name of the method which calls `#mark`:  `mark('#my_method: a section of code')`

**Example output:**

You should see some output like this when running the `World` example scene.  The first tick which renders the tile layer actually takes a long time.
```
================================================================================
Zif::TickTraceService: Slow tick.  59.609ms elapsed >  20.000ms threshold, longest step 'Zif::LayeredTileMap: #refresh: Rerendering tiles at [1800, 1200, 1280, 720]'  29.817ms:
       mark     delta label
    0.010ms   0.010ms ZifExample: #standard_tick: begin
    0.059ms   0.049ms ZifExample: #standard_tick: Scene #perform_tick complete
   29.876ms  29.817ms Zif::LayeredTileMap: #refresh: Rerendering tiles at [1800, 1200, 1280, 720]
   59.079ms  29.203ms Zif::LayeredTileMap: #refresh: Rerendered tiles
   59.098ms   0.019ms Zif::LayeredTileMap: #refresh: Rerendering stuff at [1800, 1200, 1280, 720]
   59.484ms   0.386ms Zif::LayeredTileMap: #refresh: Rerendered stuff
   59.496ms   0.012ms Zif::LayeredTileMap: #refresh: Rerendering avatar at [1800, 1200, 1280, 720]
   59.517ms   0.021ms Zif::LayeredTileMap: #refresh: Rerendered avatar
   59.528ms   0.011ms Zif::LayeredTileMap: #refresh: Rerendering top_effects at [1800, 1200, 1280, 720]
   59.539ms   0.011ms Zif::LayeredTileMap: #refresh: Rerendered top_effects
   59.545ms   0.006ms Zif::LayeredTileMap: #refresh: Rerendered all layers
   59.582ms   0.037ms ZifExample: #standard_tick: Scene switching handled
   59.609ms   0.027ms ZifExample: #standard_tick: end
```
