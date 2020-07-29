module DDQL
  class InfixStringMapOperator < Operator
    def initialize(symbol, name, ordinal)
      super(symbol, name, :infix, 4, false, :boolean, ordinal)
    end
  end
end
