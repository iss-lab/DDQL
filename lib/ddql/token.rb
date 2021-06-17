require 'forwardable'

module DDQL
  class Token
    attr_reader :data, :type
    attr_accessor :location

    using ::DDQL::StringRefinements

    def initialize(data:, location: nil, type:)
      @data     = data
      @location = location
      @type     = type
    end

    def and?
      data == 'AND'
    end

    def as_hash
      type.as_hash(data)
    end

    def comparison?
      type.comparison?(data)
    end

    def complex_comparison?
      type.complex_comparison?(data)
    end

    def infix?
      type.infix?
    end

    def math?
      type.math?(data)
    end

    def op_data
      data.squish
    end

    def or?
      data == 'OR'
    end

    def parse(parser, expression: nil)
      type.parse(parser, self, expression: expression)
    end

    def post_process(parser:, expression:)
      raise "#{type} doesn't support post-processing" unless supports_post_processing?
      type.post_process(parser: parser, expression: expression)
    end

    def postfix?
      type.postfix?
    end

    def prefix?
      type.prefix?
    end

    def simple_comparison?
      type.simple_comparison?(data)
    end

    def supports_post_processing?
      type.supports_post_processing?
    end

    def to_h
      type.as_hash(data)
    end

    def to_s
      "#{type.name} : #{data}"
    end

    def type?(token_type)
      token_type == type
    end
  end
end
