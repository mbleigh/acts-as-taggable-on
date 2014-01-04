module ActsAsTaggableOn
  module Expression
    
    # Executes a tag search using +, |, - and & operators.
    # This module parses and re-orders the tag expression to generate an SQL query 
    # without the use of subqueries and SQL set operators. 
    #
    # Usage: 
    # - Item.tagged_with("this+is&my-expression", :expression => true)
    # - | and + operators are interchangable
    #  
    # Options:
    #  :use_whitespace - use whitespace between tags and operators as delimiter; 
    #     this makes using tags with operators in them a bit easier
    #  :default_chaining - do not regroup ore reorder expression
    #
    # Examples:
    # - Item.tagged_with("programming languages - java & fun" , :expression => { :use_whitespace => true} )
    #   => returns programming langauges tagged with fun that are not java; spaces that do not separate operators are ignored
    #
    # - Item.tagged_with("programming languages + fun + java" , :expression => { :use_whitespace => true, :default_chaining => true} )
    #   => this will find the intersection of programming languages, fun and java, since the chaining is handled as follows:
    #      Item.tagged_with("programming_langugages", :any => true).tagged_with("fun", :any => true).tagged_with("java", :any => true)
    #      :default_chaining means each tag will not be reordered and will be handled individually. 
    #
    # Notes:
    # - With :use_whitespace => false, if a tag contains a +/-/|/& operator, precede operator
    #   with a "\\" or '\' to bypass parser. e.g. "c\\+\\++java" to union c++ and java. 
    # - With :use_whitespace => true, if a tag contains a space, the parser should be able to 
    #   handle it. For a tag like "you + me", precede the space in the same manner as above:
    #   "you\\ + me + them"
    # - Use "\\" (double quotes) or '\' (single quotes) to bypass parser
    #
    # Example:
    # - Item.tagged_with("c\\+\\+-java&fun" , :expression => true)
    #   => returns programming languages tagged with c++ and languages tagged with c++ as long as they are tagged with fun and they are not java.
    #
    # Limitations and future development: 
    # - Since this is a purely SQL solution and doesn't use set operators, it will evaluate + => - => & from left to right;
    # therefore 'Item.tagged_with("programming_languages-java&fun+c\\+\\+" , :expression => true)'
    # will return c++ regardless of whether it's tagged with fun. It will only return c++ if it's tagged with fun, since 
    # intersection is evaluated last. This could be improved using SQL set operators or a solution using server memory.  


    def self.options
      @options ||= {}
    end

    # provides a batch of tags from the Parse::build_each_batch method with the inputed tag as a parameter
    # with :default_chaining, use individual tuples instead of batches
    def self.next_batch(tag_list, options = {})
      @options = options
      parsed_expression = Parse.parse_expression(tag_list)
      formatted_expression = Parse.fixed_expression_array(parsed_expression)
      tuples = Parse::tuple_list(formatted_expression)
      if !options[:default_chaining] == true
        Parse::build_each_batch(tuples) do |op, tag|
          yield op, tag
        end
      else
        tuples.each do |op, tag|
          yield op, tag
        end
      end
    end

    module Parse

      REGEX_OPS = '[\|\+\-\&]'
      SPLIT_REGEX = "(#{REGEX_OPS})"
      SPLIT_REGEX_WHITESPACE = "\s+(#{REGEX_OPS})\s+"

      # + => union AKA :any
      # | => union AKA :any
      # - => difference AKA :exclude
      # & => intersection AKA :default
      def self.option_from_operator
        {"+" => :any, "|" => :any, "-" => :exclude, "&" => :intersection}
      end

      # looks for consecutive operators and subsitutes in the first 
      # prevents expression from being broken e.g. java++ruby => java+ruby
      def self.fix_operator_syntax(expression_string)
        expression_string.scan(/(?<!\\)#{REGEX_OPS}{2,}/).each do |ops|
          expression_string.gsub!(ops, ops[0])
        end
      end

      def self.fix_operator_syntax_whitespace(expression_string)
        expression_string.scan(/(?<!\\)\s#{REGEX_OPS}{2,}\s/).each do |ops|
          expression_string.gsub!(ops, " #{ops.strip[0]} ")
        end
      end

      # splits string at valid operators
      def self.parse_expression(tag_list)
        expression_string = tag_list
        expression_array = []
        if !Expression.options.delete(:use_whitespace)
          fix_operator_syntax(expression_string)
          expression_array = expression_string.split(/(?<!\\)#{SPLIT_REGEX}/)
        else
          fix_operator_syntax_whitespace(expression_string)
          expression_array = expression_string.split(/(?<!\\)#{SPLIT_REGEX_WHITESPACE}/)
        end
        return unescape_tags(expression_array)
      end

      # looks for operators preceded by backslashes and replaces with empty string
      # this returns string to original unescaped form, enabling tag operators inside of strings 
      def self.unescape_tags(expression_array)
        if !Expression.options.delete(:use_whitespace)
          unescape_with_regex(expression_array, /\\(?=#{REGEX_OPS})/)
        else
          unescape_with_regex(expression_array, /\\(?=\s)/)
        end
        return expression_array
      end

      # replaces matches with sub value 
      def self.unescape_with_regex(input, regex, sub = "")
        input.map!{|e| e.gsub(e.scan(regex)[0] || sub, sub)}.reject!(&:empty?)
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
        expression_array = expression_array.each_slice(2).map { |op, tag|  [op.strip, tag.strip]}
        if !Expression.options[:default_chaining] == true
          return sorted_expression_array(expression_array)
        else 
          return expression_array
        end
      end

      # to keep evaluation of expressions simple and consistent with 
      # existing SQL logic, the expressions are re-ordered in the following
      # manner to provide more expected (albeit still imperfect) results:
      # unions => difference => intersection
      def self.sorted_expression_array(expression_array)
        return expression_array.sort do |b, a|
          if  a[0] == "&" or (a[0] == "-" and b[0] != "&")
            sort = -1
          else sort = 1
          end
        end
      end

      # reduces calls to tagged_with by returning batches of each operator 
      # lets ActiveRecord handle chaining with predefined sorting
      def self.build_each_batch(tuples)
        current_option = nil
        tag_list = []
        tuples.each do |operator, tag|

          if  current_option != nil and current_option != option_from_operator[operator]
            yield current_option, tag_list
            tag_list = []          
          end

          current_option = option_from_operator[operator]
          tag_list.push(tag)

        end
        yield current_option, tag_list
      end
    end
  end
end

