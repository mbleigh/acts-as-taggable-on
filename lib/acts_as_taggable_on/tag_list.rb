require 'active_support/core_ext/module/delegation'

module ActsAsTaggableOn
  class TagList < Array
    attr_accessor :owner

    def initialize(*args)
      add(*args)
    end

    ##
    # Returns a new TagList using the given tag string.
    #
    # Example:
    #   tag_list = TagList.from("One , Two,  Three")
    #   tag_list # ["One", "Two", "Three"]
    def self.from(string)
      string = string.join(ActsAsTaggableOn.glue) if string.respond_to?(:join)

      new.tap do |tag_list|
        string = string.to_s.dup

        # Parse the quoted tags
        d = ActsAsTaggableOn.delimiter
        # Separate multiple delimiters by bitwise operator
        d = d.join("|") if d.kind_of?(Array)
        double_quote_pattern = %r{
          (             # Tag start delimiter ($1)
            \A       |  # Either string start or
            #{d}        # a delimiter
          )
          \s*"          # quote (") optionally preceded by whitespace
          (.*?)         # Tag ($2)
          "\s*          # quote (") optionally followed by whitespace
          (?=           # Tag end delimiter (not consumed; is zero-length lookahead)
            #{d}\s*  |  # Either a delimiter optionally followed by whitespace or
            \z          # string end
          )
        }x
        string.gsub!(double_quote_pattern) {
          # Append the matched tag to the tag list
          tag_list << $2
          # Return the matched delimiter ($3) to replace the matched items
          ''
        }
        single_quote_pattern = %r{
          (             # Tag start delimiter ($1)
            \A       |  # Either string start or
            #{d}        # a delimiter
          )
          \s*'          # quote (') optionally preceded by whitespace
          (.*?)         # Tag ($2)
          '\s*          # quote (') optionally followed by whitespace
          (?=           # Tag end delimiter (not consumed; is zero-length lookahead)
            #{d}\s*  |  # Either a delimiter optionally followed by whitespace or
            \z          # string end
          )
        }x
        string.gsub!(single_quote_pattern) {
          # Append the matched tag ($2) to the tag list
          tag_list << $2
          # Return an empty string to replace the matched items
          ''
        }

        # split the string by the delimiter
        # and add to the tag_list
        tag_list.add(string.split(Regexp.new d))
      end
    end

    ##
    # Add tags to the tag_list. Duplicate or blank tags will be ignored.
    # Use the <tt>:parse</tt> option to add an unparsed tag string.
    #
    # Example:
    #   tag_list.add("Fun", "Happy")
    #   tag_list.add("Fun, Happy", :parse => true)
    def add(*names)
      extract_and_apply_options!(names)
      concat(names)
      clean!
      self
    end

    ##
    # Remove specific tags from the tag_list.
    # Use the <tt>:parse</tt> option to add an unparsed tag string.
    #
    # Example:
    #   tag_list.remove("Sad", "Lonely")
    #   tag_list.remove("Sad, Lonely", :parse => true)
    def remove(*names)
      extract_and_apply_options!(names)
      delete_if { |name| names.include?(name) }
      self
    end

    ##
    # Transform the tag_list into a tag string suitable for editing in a form.
    # The tags are joined with <tt>TagList.delimiter</tt> and quoted if necessary.
    #
    # Example:
    #   tag_list = TagList.new("Round", "Square,Cube")
    #   tag_list.to_s # 'Round, "Square,Cube"'
    def to_s
      tags = frozen? ? self.dup : self
      tags.send(:clean!)

      tags.map do |name|
        d = ActsAsTaggableOn.delimiter
        d = Regexp.new d.join("|") if d.kind_of? Array
        name.index(d) ? "\"#{name}\"" : name
      end.join(ActsAsTaggableOn.glue)
    end

    private

    # Remove whitespace, duplicates, and blanks.
    def clean!
      reject!(&:blank?)
      map!(&:strip)
      map!{ |tag| tag.mb_chars.downcase.to_s } if ActsAsTaggableOn.force_lowercase
      map!(&:parameterize) if ActsAsTaggableOn.force_parameterize

      uniq!
    end

    def extract_and_apply_options!(args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      options.assert_valid_keys :parse

      if options[:parse]
        args.map! { |a| self.class.from(a) }
      end

      args.flatten!
    end
  end
end
