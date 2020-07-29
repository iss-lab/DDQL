module DDQL
  class PostfixNullTypeOperator < Operator
    attr_reader :pattern

    def initialize(symbol, null_type, ordinal)
      super("IS #{symbol}", "Is #{symbol}", :postfix, 9, false, :boolean, ordinal)
      @null_type = null_type
      @pattern   = /IS\s+#{symbol}/
    end
  end
end
