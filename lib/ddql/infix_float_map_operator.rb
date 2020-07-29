module DDQL
  class InfixFloatMapOperator < Operator
    attr_reader :comparison, :op_type, :op_symbol

    def initialize(symbol, name, ordinal, op_type, comparison)
      super(symbol, name, :infix, 4, false, :boolean, ordinal)
      @op_type    = op_type
      @comparison = comparison
      @op_symbol  = :"op_float_map_#{op_type}_#{comparison}"
    end
  end
end
