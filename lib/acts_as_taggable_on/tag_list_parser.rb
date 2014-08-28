module ActsAsTaggableOn
  ##
  # Returns a new TagList using the given tag string.
  #
  # Example:
  #   tag_list = ActsAsTaggableOn::TagListParser.parse("One , Two,  Three")
  #   tag_list # ["One", "Two", "Three"]
  module TagListParser
    class << self
      ## DEPRECATED
      def parse(string)
        ActiveRecord::Base.logger.warn <<WARNING
ActsAsTaggableOn::TagListParser.parse is deprecated \
and will be removed from v4.0+, use  \
ActsAsTaggableOn::TagListParser.new instead
WARNING
        DefaultParser.new(string).parse
      end
    end
  end
end
