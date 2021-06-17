module DDQL
  class PostfixNullTypeOperator < Operator
    attr_reader :pattern

    def initialize(symbol, null_type)
      super("IS #{symbol}", "Is #{symbol}", :postfix, 9, false, :boolean)
      @null_type = null_type
      @pattern   = /IS\s+#{symbol}/
    end
  end
end
