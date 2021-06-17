module DDQL
  class ListOperator < Operator
    def initialize(symbol, name, type)
      super(symbol, name, type, 4, false, :boolean)
    end
  end
end
