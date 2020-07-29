module DDQL
  class ListOperator < Operator
    def initialize(symbol, name, type, ordinal)
      super(symbol, name, type, 4, false, :boolean, ordinal)
    end
  end
end
