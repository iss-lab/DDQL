module DDQL
  class Parser
    class ParseException < StandardError
    end

    class NoTokenException < ParseException
      def initialize
        super 'No token found - ensure literals are surrounded by single quotes'
      end
    end

    def initialize(expression)
      @expression = expression
      @tokens     = Lexer.lex(expression)
      @depth      = 0
    end

    def consume(token_type)
      token = @tokens.poll
      if token.nil? || token_type != token.type
        message  = "Expected token[#{token_type.name}], got #{token.nil? ? 'nil' : "[#{token.type.name}]"}\n"
        if token
          message += "    #{@expression}\n"
          message += "    #{' ' * token.location}^"
        end
        raise ParseException, message
      end
      token
    end

    def parse(precedence: 0)
      @depth += 1
      token   = @tokens.poll
      raise NoTokenException if token.nil?

      expression = token.parse(self)
      while precedence < next_precedence
        token = @tokens.poll
        expression = token.parse(self, expression: expression)
      end
      @depth -= 1

      if @depth == 0 && !peek.nil?
        raise ParseException, "Unable to fully parse expression; token[#{peek}], possible cause: invalid operator"
      end

      expression
    end

    def peek
      @tokens.peek
    end

    private
    def next_precedence
      token = peek
      return 0 if token.nil?
      Operators.instance.cache[token.op_data]&.precedence || 0
    end
  end
end
