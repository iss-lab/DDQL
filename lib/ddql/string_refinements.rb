module DDQL
  module StringRefinements
    refine String do
      def squish
        self.dup.squish!
      end

      def squish!
        # this implementation is required (vs. just chaining message calls)
        # because string! and gsub! return `nil` if nothing changes
        strip!
        gsub!(/[[:space:]]+/, ' ')
        self
      end    
    end
  end
end
