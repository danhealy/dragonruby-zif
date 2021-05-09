module Zif
  # A mixin to allow compatibility with {Zif::Services::InputService}
  #
  # Set key down handler attributes {on_key_down} to Lambdas accepting the +key+
  # argument to do something with this object when keyboard events happen.
  #
  module KeyPressable
    # @return [Lambda] Called when the key is pressed down.  Called with the +key+ that was pressed
    attr_accessor :on_key_down

    # @param [<String>] text_key a single character from the keyboard, suitable for adding to the field
    # @param [Array<Symbol>] all_keys truthy values from the keyboard includes modifiers like delete and backspace.
    # @return nil
    def handle_key(text_key, all_keys)
      # puts "KeyPressable: handle_key?: #{text_key} :#{all_keys}"
      on_key_down&.call(text_key, all_keys)
    end
  end
end
