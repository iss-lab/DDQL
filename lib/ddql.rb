require 'ddql/version'
require_relative 'ddql/linked_list'
require_relative 'ddql/query_expression_error'
require_relative 'ddql/lexer'
require_relative 'ddql/operators'
require_relative 'ddql/parser'
require_relative 'ddql/string_refinements'
require_relative 'ddql/token_type'
require_relative 'ddql/token'


module DDQL
  class ParseError < StandardError; end
end
