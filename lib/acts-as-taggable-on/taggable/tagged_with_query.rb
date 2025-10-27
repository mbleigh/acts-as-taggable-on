# frozen_string_literal: true

module ActsAsTaggableOn
  module Taggable
    module TaggedWithQuery
      def self.build(taggable_model, tag_model, tagging_model, tag_list, options)
        if options[:exclude].present?
          ExcludeTagsQuery.new(taggable_model, tag_model, tagging_model, tag_list, options).build
        elsif options[:any].present?
          AnyTagsQuery.new(taggable_model, tag_model, tagging_model, tag_list, options).build
        else
          AllTagsQuery.new(taggable_model, tag_model, tagging_model, tag_list, options).build
        end
      end
    end
  end
end
