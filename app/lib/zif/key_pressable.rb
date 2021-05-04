module Zif
  # A mixin to allow compatibility with {Zif::Services::InputService}
  #
  # Set key down handler attributes {on_key_down} to Lambdas accepting the +key+
  # argument to do something with this object when keyboard events happen.
  #
  module KeyPressable
    # @return [Lambda] Called when the key is pressed down.  Called with the +key+ that was pressed
    attr_accessor :on_key_down

    # @param [key<Symbol>] see GTK::KeyboardKeys for symbols
    # @param [kind<Symbol>] kind The kind of key coming through, right now we're only sending downs
    # @return nil
    def handle_key(key, kind=:down)
      # puts "KeyPressable:#{@name}: handle_key?: #{key} :#{kind} :#{on_key_down}"
      on_key_down&.call(key)
    end
  end
end
