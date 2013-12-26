module ActsAsTaggableOn
  module Expression
    
    ##
    # Executes a tag search using +, - and & operators.
    # Use the :expression option to add an expression string.
    # Use the :default_chaining to evaluate the expression using onyl ActiveRecord chaining.
    # However, default chaining may return less than desired results. 
    #
    # Example:
    #   Item.tagged_with("programming_languages-java&fun" , :expression => true)
    #   => returns programming langauges tagged with fun that are not java.


    # + => union AKA :any
    # - => difference AKA :exclude
    # & => intersection AKA :default
    def self.option_from_operator
      {"+" => :any, "-" => :exclude, "&" => :default}
    end

    def self.options
      @options ||= {}
    end

    #provides a batch of tags from the Parse::build_each_batch method with the inputed tag as a parameter
    def self.next_batch(tag_list, options = {})
      @options = options
      parsed_expression = Parse.parse_expression(tag_list)
      formatted_expression = Parse.fixed_expression_array(parsed_expression)
      tuples = Parse::tuple_list(formatted_expression)
      Parse::build_each_batch(tuples) do |op, tag|
        yield op, tag
      end
    end

    module Parse

      REGEX_OPS = '[\+\-\&]'

      # looks for consecutive operators and subsitutes in the first 
      # prevents expression from being broken e.g. java++ruby => java+ruby
      def self.fix_operator_syntax(expression_string)
        expression_string.scan(/#{REGEX_OPS}{2,}/).each do |ops|
          expression_string.gsub!(ops, ops[0])
        end
      end

      # elminates all white space from expression string
      # splits string at valid operators
      # if Ruby version >= 1.9, does not split if preceded by back slash
      def self.parse_expression(tag_list)
        expression_string = tag_list.gsub(/\s+/, "")
        fix_operator_syntax(expression_string)
        expression_array = if RUBY_VERSION.to_f >= 1.9
          expression_string.split(/(?<!\\)(#{REGEX_OPS})/) #if negative lookbehinds are available
        else 
          expression_string.split(/(#{REGEX_OPS})/)
        end

        return unescape_tags(expression_array)
      end

      # looks for operators preceded by backslashes and replaces with empty string
      # this returns string to original unescaped form, enabling tag operators inside of strings 
      def self.unescape_tags(expression_array)
        expression_array.map!{|e| e.gsub(e.scan(/\\(?=#{REGEX_OPS})/)[0] || "","")}.reject!(&:empty?)
        return expression_array
      end

      # insert + if first character is not an operator
      # meaning that in default case, the first tag will be handled as union, or :any
      def self.fixed_expression_array(expression_array)
        expression_array.insert(0, "+") if /^#{REGEX_OPS}/ !~ expression_array[0] 
        return expression_array
      end

      # converts split expression array into tuples in the form [operator, tag]
      # provides option of using default ActiveRecord chaining order using :default_chaining option 
      def self.tuple_list(expression_array)
        expression_array = expression_array.each_slice(2).map { |name, type|  [name, type]}
        if !ActsAsTaggableOn::Expression.options.delete(:default_chaining)
          return sorted_expression_array(expression_array) # move & to the back
        else sorted_expression_array(expression_array)
          return expression_array
        end
      end

      # when an interection is handled between differences and unions
      # ActiveRecord's default chaining can provide unexpected results
      # & operator tuples are moved to back of list, which also preserves order of operations 
      def self.sorted_expression_array(expression_array)
        return expression_array.sort{|a,b| a[0] != "&" ? -1 : 1}
      end

      # reduces calls to tagged_with by returning batches of each operator 
      # lets ActiveRecord handle ordering unless  sorting is specified 
      def self.build_each_batch(tuples)
        current_op = nil
        list = []
        tuples.each do |op, tag|
          if op != current_op and current_op != nil
            yield current_op, list
            list = []          
          end

          current_op = op
          list.push(tag)

        end
        yield current_op, list
      end
    end
  end
end