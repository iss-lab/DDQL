require_relative 'linked_list'

module DDQL
  class Lexer
    def self.lex(expression, pattern: TokenType.all_types_pattern, available_types: TokenType::ALL)
      tokens = LinkedList.new.doubly_linked!
      md = pattern.match expression
      while md
        token_type = available_types.detect { |tt| tt.match?(match_data: md) }
        if token_type
          tokens << Token.new(
            data: token_type.interpreted_data_from(match_data: md),
            location: expression.length - md.string.length,
            type: token_type,
          )
        end
        md = pattern.match md.post_match
      end
      tokens
    end
  end
end
