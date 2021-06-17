describe DDQL::Lexer do
  example 'matches attribute' do
    expr   = '[foo]'
    tokens = DDQL::Lexer.lex(expr)
    expect(tokens.head.value.type).to eq DDQL::TokenType::FACTOR
    expect(tokens.head.value.data).to eq 'foo'
  end

  example 'matches braces' do
    expr   = '{chomp chomp chimp}'
    tokens = DDQL::Lexer.lex(expr)
    expect(tokens.head.value.type).to eq DDQL::TokenType::LBRACE
    expect(tokens.tail.value.type).to eq DDQL::TokenType::RBRACE
  end

  example 'subquery with fields' do
    expr = "SUM{type:IssuerPerson, fields: [NoDirMatTransactions], expression: [ipAssociationType] == 'Director'}"
    # require 'pry' ; binding.pry
    tokens = DDQL::Lexer.lex(expr)
    expect(tokens.size).to eq 6
    [
      ['prefixoperator', 'SUM'],
      ['lbrace', '{'],
      ['sub_query_type', 'IssuerPerson'],
      ['sub_query_fields', 'NoDirMatTransactions'],
      ['sub_query_expression', "[ipAssociationType] == 'Director'"],
      ['rbrace', '}'],
    ].each do |type, data|
      token = tokens.poll
      expect(token.type.label).to eq type
      expect(token.data).to eq data
    end
  end

  example 'subquery without fields' do
    expr = "CNT{type:IssuerPerson, expression: [NomineeType] == 'Mgmt Continuing'}"
    tokens = DDQL::Lexer.lex(expr)
    expect(tokens.size).to eq 5
    [
      ['prefixoperator', 'CNT'],
      ['lbrace', '{'],
      ['sub_query_type', 'IssuerPerson'],
      ['sub_query_expression', "[NomineeType] == 'Mgmt Continuing'"],
      ['rbrace', '}'],
    ].each do |type, data|
      token = tokens.poll
      expect(token.type.label).to eq type
      expect(token.data).to eq data
    end
  end

  example 'subquery without fields' do
    expr = "CNT{type:IssuerPerson, expression: [NomineeType] == 'Mgmt Continuing'}"
    tokens = DDQL::Lexer.lex(expr)
    expect(tokens.size).to eq 5
    [
      ['prefixoperator', 'CNT'],
      ['lbrace', '{'],
      ['sub_query_type', 'IssuerPerson'],
      ['sub_query_expression', "[NomineeType] == 'Mgmt Continuing'"],
      ['rbrace', '}'],
    ].each do |type, data|
      token = tokens.poll
      expect(token.type.label).to eq type
      expect(token.data).to eq data
    end
  end

  example 'subquery with grouping' do
    expr = "MIN {type: Issuer, fields: [oekomCarbonRiskRating]} GROUP BY [oekomIndustry]"
    tokens = DDQL::Lexer.lex(expr)
    expect(tokens.size).to eq 6
    [
      ['prefixoperator', 'MIN'],
      ['lbrace', '{'],
      ['sub_query_type', 'Issuer'],
      ['sub_query_fields', 'oekomCarbonRiskRating'],
      ['rbrace', '}'],
      ['sub_query_grouping', 'oekomIndustry'],
    ].each do |(type, data)|
      token = tokens.poll
      expect(token.type.label).to eq type
      expect(token.data).to eq data
    end
  end

  # TODO: uncomment the following if/when we decide to handle capture groups
  # example 'matches capture groups' do
  #   expr   = '(%basil%)'
  #   tokens = DDQL::Lexer.lex(expr)
  #   expect(tokens.head.value.type).to eq DDQL::TokenType::LCAPTURE
  #   expect(tokens.tail.value.type).to eq DDQL::TokenType::RCAPTURE
  # end

  example 'matches literal' do
    expr   = "'peas porridge hot'"
    tokens = DDQL::Lexer.lex(expr)
    expect(tokens.head.value.type).to eq DDQL::TokenType::STRING_LITERAL
    expect(tokens.head.value.data).to eq 'peas porridge hot'
  end

  example 'matches parens' do
    expr   = '([foo] IS NOT NULL)'
    tokens = DDQL::Lexer.lex(expr)
    expect(tokens.head.value.type).to eq DDQL::TokenType::LPAREN
    expect(tokens.tail.value.type).to eq DDQL::TokenType::RPAREN
  end

  example 'matches screen name' do
    expr   = "[screen#123]"
    tokens = DDQL::Lexer.lex(expr)
    expect(tokens.head.value.type).to eq DDQL::TokenType::SCREEN
    expect(tokens.head.value.data).to eq 'screen#123'
  end

  example 'matches symbol' do
    expr   = "$CURRENT_YEAR"
    tokens = DDQL::Lexer.lex(expr)
    expect(tokens.head.value.type).to eq DDQL::TokenType::SPECIAL_MARKER
    expect(tokens.head.value.data).to eq 'CURRENT_YEAR'
  end

  context 'infixes' do
    DDQL::Operators.instance.cache.select{ |k, v| v.type == :infix }.keys.each do |infix|
      example "matches #{infix}" do
        expr   = "[Blaz] #{infix} '1.23'"
        tokens = DDQL::Lexer.lex(expr)
        expect(tokens.head.next.value.type).to eq DDQL::TokenType::INFIXOPERATOR
        expect(tokens.head.next.value.data).to eq infix
      end
    end
  end

  context 'postfixes' do
    DDQL::Operators.instance.cache.select{ |_k, v| v.type == :postfix && v.name !~ /Nested Query/ }.keys.each do |postfix|
      example "matches #{postfix}" do
        expr   = "[FooBar] #{postfix}"
        tokens = DDQL::Lexer.lex(expr)
        expect(tokens.tail.value.type).to eq DDQL::TokenType::POSTFIXOPERATOR
        expect(tokens.tail.value.data).to eq postfix
      end
    end
  end

  context 'prefixes' do
    DDQL::Operators.instance.cache.select{ |_k, v| v.type == :prefix && v.name !~ /Nested Query/ }.keys.each do |prefix|
      example "matches #{prefix}" do
        expr   = "#{prefix} { fields: [Foobar], type: Issuer, expression: [ipAssociationType] == 'Director' }"
        tokens = DDQL::Lexer.lex(expr)
        expect(tokens.head.value.type).to eq DDQL::TokenType::PREFIXOPERATOR
        expect(tokens.head.value.data).to eq prefix
      end
    end
  end

  context 'expressions' do
    example 'nullness' do
      expr = "[Foo] IS NOT NULL AND [Bar] IS NOT_COLLECTED"
      tokens = DDQL::Lexer.lex(expr).each
      [
        ['Foo', DDQL::TokenType::FACTOR],
        ['IS NOT NULL', DDQL::TokenType::POSTFIXOPERATOR],
        ['AND', DDQL::TokenType::INFIXOPERATOR],
        ['Bar', DDQL::TokenType::FACTOR],
        ['IS NOT_COLLECTED', DDQL::TokenType::POSTFIXOPERATOR],
      ].each do |(data, type)|
        value = tokens.next
        expect(value.data).to eq data
        expect(value.type).to eq type
      end
    end

    example 'literal comparison of strings' do
      %w[== =].each do |op|
        expr = "[Baz] #{op} 'abcde'"
        tokens = DDQL::Lexer.lex(expr).each
        [
          ['Baz', DDQL::TokenType::FACTOR],
          [op, DDQL::TokenType::INFIXOPERATOR],
          ['abcde', DDQL::TokenType::STRING_LITERAL],
        ].each do |(data, type)|
          value = tokens.next
          expect(value.data).to eq data
          expect(value.type).to eq type
        end
      end
    end

    example 'literal comparison of empty strings' do
      %w[== =].each do |op|
        expr = "[Baz] #{op} '' OR [Foo] != 'what are we sayin'"
        tokens = DDQL::Lexer.lex(expr).each
        [
          ['Baz', DDQL::TokenType::FACTOR],
          [op, DDQL::TokenType::INFIXOPERATOR],
          ['', DDQL::TokenType::STRING_LITERAL],
          ['OR', DDQL::TokenType::INFIXOPERATOR],
          ['Foo', DDQL::TokenType::FACTOR],
          ['!=', DDQL::TokenType::INFIXOPERATOR],
          ['what are we sayin', DDQL::TokenType::STRING_LITERAL],
        ].each do |(data, type)|
          value = tokens.next
          expect(value.data).to eq data
          expect(value.type).to eq type
        end
      end
    end

    example 'literal comparison of strings with escaped ticks' do
      %w[== =].each do |op|
        expr = "[Foo] != 'Deming' AND [Baz] #{op} 'O\\'Reilly'"
        tokens = DDQL::Lexer.lex(expr).each
        [
          ['Foo', DDQL::TokenType::FACTOR],
          ['!=', DDQL::TokenType::INFIXOPERATOR],
          ['Deming', DDQL::TokenType::STRING_LITERAL],
          ['AND', DDQL::TokenType::INFIXOPERATOR],
          ['Baz', DDQL::TokenType::FACTOR],
          [op, DDQL::TokenType::INFIXOPERATOR],
          ["O'Reilly", DDQL::TokenType::STRING_LITERAL],
        ].each do |(data, type)|
          value = tokens.next
          expect(value.data).to eq data
          expect(value.type).to eq type
        end
      end
    end

    example 'literal comparison of strings with multiple ticks' do
      %w[== =].each do |op|
        expr = "[Baz] #{op} 'abc'de' OR [Foo] != 'what are we sayin'"
        tokens = DDQL::Lexer.lex(expr).each
        [
          ['Baz', DDQL::TokenType::FACTOR],
          [op, DDQL::TokenType::INFIXOPERATOR],
          ['abc', DDQL::TokenType::STRING_LITERAL],
        ].each do |(data, type)|
          value = tokens.next
          expect(value.data).to eq data
          expect(value.type).to eq type
        end
      end
    end

    example 'literal comparison of non-integer' do
      expr = "[Prime] != '17\\'3\"'"
      tokens = DDQL::Lexer.lex(expr).each
      [
        ['Prime', DDQL::TokenType::FACTOR],
        ['!=', DDQL::TokenType::INFIXOPERATOR],
        [%{17'3"}, DDQL::TokenType::STRING_LITERAL],
      ].each do |(data, type)|
        value = tokens.next
        expect(value.data).to eq data
        expect(value.type).to eq type
      end
    end

    example 'literal comparison of integer' do
      expr = "[Prime] != '17'"
      tokens = DDQL::Lexer.lex(expr).each
      [
        ['Prime', DDQL::TokenType::FACTOR],
        ['!=', DDQL::TokenType::INFIXOPERATOR],
        [17, DDQL::TokenType::INTEGER_LITERAL],
      ].each do |(data, type)|
        value = tokens.next
        expect(value.data).to eq data
        expect(value.type).to eq type
      end
    end

    example 'literal comparison of scientific number' do
      expr = "[Primeish] <= '3.57e-10'"
      tokens = DDQL::Lexer.lex(expr).each
      [
        ['Primeish', DDQL::TokenType::FACTOR],
        ['<=', DDQL::TokenType::INFIXOPERATOR],
        [3.57e-10, DDQL::TokenType::SCI_NUM_LITERAL],
      ].each do |(data, type)|
        value = tokens.next
        expect(value.data).to eq data
        expect(value.type).to eq type
      end
    end

    example 'literal comparison of floating point number' do
      expr = "[PrimeishAgain] <= '11.13'"
      tokens = DDQL::Lexer.lex(expr).each
      [
        ['PrimeishAgain', DDQL::TokenType::FACTOR],
        ['<=', DDQL::TokenType::INFIXOPERATOR],
        [11.13, DDQL::TokenType::NUMERIC_LITERAL],
      ].each do |(data, type)|
        value = tokens.next
        expect(value.data).to eq data
        expect(value.type).to eq type
      end
    end
  end
end
