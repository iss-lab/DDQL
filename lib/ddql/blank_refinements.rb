module DDQL
  module BlankRefinements
    refine Enumerable do
      def blank?
        empty? || compact.empty?
      end
    end

    refine Hash do
      def blank?
        empty? || compact.empty?
      end
    end

    refine NilClass do
      def blank?
        true
      end
    end
  end
end
