# frozen_string_literal: true

module ActsAsTaggableOn
  module Taggable
    module Cache
      extend ActiveSupport::Concern

      class_methods do
        # ActiveRecord::Base.columns makes a database connection and caches the
        #   calculated columns hash for the record as @columns. Since we don't
        #   want to add caching methods until we confirm the presence of a
        #   caching column, and we don't want to force opening a database
        #   connection when the class is loaded, here we intercept and cache
        #   the call to :columns as @acts_as_taggable_on_cache_columns
        #   to mimic the underlying behavior. While processing this first
        #   call to columns, we do the caching column check and dynamically add
        #   the class and instance methods
        #   FIXME: this method cannot compile in rubinius
        def columns
          @acts_as_taggable_on_cache_columns ||= begin
                                                   db_columns = super
                                                   if _has_tags_cache_columns?(db_columns)
                                                     _add_tags_caching_methods
                                                   end

                                                   db_columns
                                                 end
        end

        def reset_column_information
          super
          @acts_as_taggable_on_cache_columns = nil
        end

        private

        # @private
        def _has_tags_cache_columns?(db_columns)
          db_column_names = db_columns.map(&:name)
          tag_types.any? do |context|
            db_column_names.include?("cached_#{context.to_s.singularize}_list")
          end
        end

        # @private
        def _add_tags_caching_methods
          include ActsAsTaggableOn::Taggable::Caching
          initialize_tags_cache
        end
      end
    end
  end
end