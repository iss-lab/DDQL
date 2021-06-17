module DDQL
  class InfixStringMapOperator < Operator
    def initialize(symbol, name)
      super(symbol, name, :infix, 4, false, :boolean)
    end
  end
end
