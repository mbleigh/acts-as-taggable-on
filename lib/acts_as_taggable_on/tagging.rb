module ActsAsTaggableOn
  class Tagging < ::ActiveRecord::Base #:nodoc:
    attr_accessible :tag,
                    :tag_id,
                    :context,
                    :taggable,
                    :taggable_type,
                    :taggable_id,
                    :tagger,
                    :tagger_type,
                    :tagger_id if defined?(ActiveModel::MassAssignmentSecurity)
    belongs_to :tag, :class_name => 'ActsAsTaggableOn::Tag'
    belongs_to :taggable, :polymorphic => true
    belongs_to :tagger,   :polymorphic => true

    validates_presence_of :context
    validates_presence_of :tag_id

    validates_uniqueness_of :tag_id, :scope => [:taggable_type, :taggable_id, :context, :tagger_id, :tagger_type]

    after_destroy :remove_unused_tags

    # Conditionally adds a counter cache when cache column is present.
    #  We just regenerate the association. It's the easiest way.
    # TODO: require the counter cache in release 4.0.0 and remove these methods
    # @see :columns in ActsAsTaggableOn::Taggable::Cache
    def self.columns
      @acts_as_taggable_on_counter_columns ||= begin
        db_columns = super
        belongs_to :tag, :class_name => 'ActsAsTaggableOn::Tag', :counter_cache => ActsAsTaggableOn::Tag.column_names.include?('taggings_count')
        db_columns
      end
    end



    private

    def remove_unused_tags
      if ActsAsTaggableOn.remove_unused_tags
        # TODO: use taggings_count in release 4.0.0
        if tag.taggings.count.zero?
          tag.destroy
        end
      end
    end
  end
end
