require 'singleton'

require_relative 'operator'
require_relative 'agg_operator'
require_relative 'coalesce_operator'
require_relative 'infix_float_map_operator'
require_relative 'infix_string_map_operator'
require_relative 'list_operator'
require_relative 'lookup_operator'
require_relative 'postfix_null_type_operator'

module DDQL
  class Operators
    include Singleton

    attr_reader :cache

    def self.float_map_ops
      instance.cache.select { |_, v| v.is_a? InfixFloatMapOperator }
    end

    def self.operator_regex(operator_type)
      ops = instance.cache.select { |k, v| v.type?(operator_type) }
      
      if ops.empty?
        # if there are no registered operators of the given type use negative
        # lookahead to generate a regex pattern that can never be matched
        return /(?!x)x/
      else
        ops.keys[1..-1].inject(ops.keys.first) { |a, e| Regexp.union(a, ops[e].pattern) }
      end
    end

    def initialize
      @cache = build_cache
    end

    private
    def build_cache
      cache = {}
      Operator.new("==", "Double Equals", :infix, 3, false, :boolean, 0).register(cache)
      Operator.new("=", "Single Equals", :infix, 3, false, :boolean, 0).register(cache)
      Operator.new("!=", "Not Equals", :infix, 3, false, :boolean, 1).register(cache)
      Operator.new("<=", "Less Than or Equals", :infix, 4, false, :boolean, 4).register(cache)
      Operator.new("<", "Less Than", :infix, 4, false, :boolean, 2).register(cache)
      Operator.new(">=", "Greater Than or Equals", :infix, 4, false, :boolean, 5).register(cache)
      Operator.new(">", "Greater Than", :infix, 4, false, :boolean, 3).register(cache)
      # Operator.new("GROUP BY", "Group By", :infix, 7, false, :double).register(cache)
      Operator.new("CTN", "Contains", :infix, 4, false, :boolean, 6).register(cache)
      Operator.new("STW", "Starts With", :infix, 4, false, :boolean, 7).register(cache)
      Operator.new("IN", "In Any", :infix, 4, false, :boolean, 8).register(cache)
      Operator.new("LCTN", "Contains", :infix, 4, false, :boolean, 6).register(cache)
      Operator.new("ON", "On Date", :infix, 4, false, :boolean, 0).register(cache)
      Operator.new("EPST", "On Or After Date", :infix, 4, false, :boolean, 1).register(cache)
      Operator.new("PST", "After Date", :infix, 4, false, :boolean, 1).register(cache)
      Operator.new("EPRE", "On Or Before Date", :infix, 4, false, :boolean, 1).register(cache)
      Operator.new("PRE", "Before Date", :infix, 4, false, :boolean, 0).register(cache)
      Operator.new("OR", "Or", :infix, 1, false, :boolean).register(cache)
      Operator.new("AND", "And", :infix, 2, false, :boolean).register(cache)
      Operator.new("IS NULL", "Is Null", :postfix, 9, false, :boolean, 0).register(cache)
      Operator.new("IS NOT NULL", "Is Not Null", :postfix, 9, false, :boolean, 1).register(cache)
      Operator.new("+", "Plus", :infix, 5, false, :double).register(cache)
      Operator.new("-", "Minus", :infix, 5, false, :double).register(cache)
      Operator.new("*", "Multiplied By", :infix, 6, false, :double).register(cache)
      Operator.new("/", "Divided By", :infix, 6, false, :double).register(cache)
      Operator.new("%", "Modulus", :infix, 6, false, :integer).register(cache)
      Operator.new("^", "To the Power of", :infix, 7, true, :double).register(cache)
      AggOperator.new("EXISTS", "Exists", return_type: :boolean).register(cache)
      AggOperator.new("CNT", "Count", return_type: :integer).register(cache)
      AggOperator.new("AVG", "Mean", return_type: :double).register(cache)
      AggOperator.new("MED", "Median", return_type: :double).register(cache)
      AggOperator.new("MAX", "Max", return_type: :double).register(cache)
      AggOperator.new("MIN", "Min", return_type: :double).register(cache)
      AggOperator.new("SUM", "Sum", return_type: :double).register(cache)
      AggOperator.new("MERGE", "Merge", return_type: :string_list).register(cache)
      LookupOperator.new.register(cache)
      CoalesceOperator.new.register(cache)
      # PNT & RATIO don't work and aren't used in DD PROD as of 2020-07-24
      # AggOperator.new("PNT", "Percent", return_type: :double).register(cache)
      # AggOperator.new("RATIO", "Ratio", return_type: :double).register(cache)
      InfixStringMapOperator.new("ANY_MAP", "Has Any", 0).register(cache)
      InfixStringMapOperator.new("ALL_MAP", "Has All", 1).register(cache)
      InfixStringMapOperator.new("NONE_MAP", "Has None", 2).register(cache)
      InfixFloatMapOperator.new("ANY_GREATER_THAN_FLOAT_MAP", "Has Any Greater Than", 1, :any, :gt).register(cache)
      InfixFloatMapOperator.new("ALL_GREATER_THAN_FLOAT_MAP", "Has All Greater Than", 2, :all, :gt).register(cache)
      InfixFloatMapOperator.new("NONE_GREATER_THAN_FLOAT_MAP", "Has None Greater Than", 3, :none, :gt).register(cache)
      InfixFloatMapOperator.new("ANY_GREATER_THAN_OR_EQUAL_FLOAT_MAP", "Has Any Greater Than Or Equal To", 4, :any, :ge).register(cache)
      InfixFloatMapOperator.new("ALL_GREATER_THAN_OR_EQUAL_FLOAT_MAP", "Has All Greater Than Or Equal To", 5, :all, :ge).register(cache)
      InfixFloatMapOperator.new("NONE_GREATER_THAN_OR_EQUAL_FLOAT_MAP", "Has None Greater Than Or Equal To", 6, :none, :ge).register(cache)
      InfixFloatMapOperator.new("ANY_LESS_THAN_FLOAT_MAP", "Has Any Less Than", 7, :any, :lt).register(cache)
      InfixFloatMapOperator.new("ALL_LESS_THAN_FLOAT_MAP", "Has All Less Than", 8, :all, :lt).register(cache)
      InfixFloatMapOperator.new("NONE_LESS_THAN_FLOAT_MAP", "Has None Less Than", 9, :none, :lt).register(cache)
      InfixFloatMapOperator.new("ANY_LESS_THAN_OR_EQUAL_FLOAT_MAP", "Has Any Less Than Or Equal To", 10, :any, :le).register(cache)
      InfixFloatMapOperator.new("ALL_LESS_THAN_OR_EQUAL_FLOAT_MAP", "Has All Less Than Or Equal To", 11, :all, :le).register(cache)
      InfixFloatMapOperator.new("NONE_LESS_THAN_OR_EQUAL_FLOAT_MAP", "Has None Less Than Or Equal To", 12, :none, :le).register(cache)
      InfixFloatMapOperator.new("ANY_EQUAL_FLOAT_MAP", "Has Any Equal To", 13, :any, :eq).register(cache)
      InfixFloatMapOperator.new("ALL_EQUAL_FLOAT_MAP", "Has All Equal To", 14, :all, :eq).register(cache)
      InfixFloatMapOperator.new("NONE_EQUAL_FLOAT_MAP", "Has None Equal To", 15, :none, :eq).register(cache)
      ListOperator.new("ANY", "Has Any", :infix, 0).register(cache)
      ListOperator.new("ALL", "Has All", :infix, 1).register(cache)
      ListOperator.new("NONE", "Has None", :infix, 2).register(cache)
      ListOperator.new("EMPTY", "Is Empty", :postfix, 3).register(cache)
      PostfixNullTypeOperator.new("NO_INFORMATION", :NoInformation, 99).register(cache)
      PostfixNullTypeOperator.new("NOT_APPLICABLE", :NotApplicable, 101).register(cache)
      PostfixNullTypeOperator.new("NOT_COLLECTED", :NotCollected, 103).register(cache)
      PostfixNullTypeOperator.new("NOT_DISCLOSED", :NotDisclosed, 100).register(cache)
      PostfixNullTypeOperator.new("NOT_MEANINGFUL", :NotMeaningful, 102).register(cache)
      Operator.new("NOT", "Not", :prefix, 9, false, :boolean).register(cache)
      Operator.new("YES", "Is True", :postfix, 9, false, :boolean, 0).register(cache)
      Operator.new("NO", "Is False", :postfix, 9, false, :boolean, 1).register(cache)
    end
  end
end
