module Zif
  # A mixin for automatically definining +#serialize+ based on instance variables with setter methods
  #
  # If you have circular references in ivars (Foo.bar <-> Bar.foo), make sure one of the classes overrides
  # {exclude_from_serialize} and specifies the attr.
  #
  # @example
  #   # Throw this file into your app folder, like app/lib/serializable.rb
  #
  #   # In your main.rb or wherever you require files:
  #   require 'app/lib/serializable.rb'
  #
  #   # In each class you want to automatically serialize:
  #   class Foo
  #     include Zif::Serializable
  #     ...
  #   end
  module Serializable
    # @return [String] Convert {serialize} to string
    def inspect
      serialize.to_s
    end

    # @return [String] Convert {serialize} to string
    def to_s
      serialize.to_s
    end

    # @return [Hash<Symbol, Object>] Convert {serialize} to string
    def serialize
      attrs = {}
      instance_variables.each do |var|
        str = var.to_s.gsub('@', '')
        next if exclude_from_serialize.include? str

        attrs[str.to_sym] = instance_variable_get var if respond_to? "#{str}="
      end
      attrs
    end

    # In the included class, override this method to exclude attrs from serialization / printing
    # @return [Array<Symbol>] Names of attributes to exclude from serialization
    def exclude_from_serialize
      %w[args] # Too much spam
    end
  end
end
