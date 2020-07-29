module DDQL
  class QueryExpressionError < StandardError
    attr_reader :cause, :expression

    def initialize(expression:, cause: nil, message: nil)
      @cause      = cause
      @expression = expression
      @message    = message || (cause ? cause.message : 'invalid expression')
    end

    def to_s
      "failed to parse #{@expression}: #{@message}"
    end
  end
end
