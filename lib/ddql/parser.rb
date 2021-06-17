module DDQL
  class Parser
    attr_reader :tokens

    class ParseException < StandardError
    end

    class NoTokenException < ParseException
      def initialize
        super 'No token found - ensure literals are surrounded by single quotes'
      end
    end

    class ResolvedToken
      attr_reader :value

      def initialize(v)
        @value = v
      end

      def parse(_)
        value
      end
    end

    def self.from_tokens(tokens)
      opener = tokens.doubly_linked!.find { |node| node.value.type == TokenType::NESTED_OPENER }
      if opener
        closer = tokens.find_from_tail { |node| node.value.type == TokenType::NESTED_CLOSER }
        new_tokens  = DDQL::LinkedList.new
        current = opener
        while (current = current.next) && !(current === closer)
          new_tokens << current.dup
        end
        new_tokens.tail.next = nil
        new(tokens: tokens.replace!(
          from: opener,
          to: closer,
          with: ResolvedToken.new(sub_query: from_tokens(new_tokens).parse)),
        )
      else
        new(tokens: tokens)
      end
    end

    def self.parse(expr)
      from_tokens(Lexer.lex(expr)).record_expression(expr).parse
    end

    def initialize(expression: nil, tokens: nil)
      @expression = expression
      @depth      = 0
      if expression
        @tokens = Lexer.lex(expression)
      else
        @tokens = tokens
      end
      raise "tokens cannot be determined" if @tokens.nil? || @tokens.empty?
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

    def record_expression(expr)
      @expression = expr
      self
    end

    # supports reading until the next +token_type+, does not support
    # nested reads of +token_type+
    #
    # @raise [RuntimeError] if +token_type+ is not found
    # @return [LinkedList<Token>] tokens exclusive of the final token_type
    def until(token_type)
      new_list = LinkedList.new.doubly_linked!
      while token = @tokens.poll
        if token.type?(token_type)
          return new_list
        else
          new_list << token
        end
      end
      raise "expected to consume tokens up to type[#{token_type.name}]"
    end

    private
    def next_precedence
      token = peek
      return 0 if token.nil?
      Operators.instance.cache[token.op_data]&.precedence || 0
    end
  end
end
