module ActsAsTaggableOn
  class Tagging < ::ActiveRecord::Base #:nodoc:
    #TODO, remove from 4.0.0
    attr_accessible :tag,
                    :tag_id,
                    :context,
                    :taggable,
                    :taggable_type,
                    :taggable_id,
                    :tagger,
                    :tagger_type,
                    :tagger_id if defined?(ActiveModel::MassAssignmentSecurity)

    belongs_to :tag, class_name: 'ActsAsTaggableOn::Tag' , counter_cache: true
    belongs_to :taggable, polymorphic: true
    belongs_to :tagger,   polymorphic: true

    validates_presence_of :context
    validates_presence_of :tag_id

    validates_uniqueness_of :tag_id, scope: [:taggable_type, :taggable_id, :context, :tagger_id, :tagger_type]

    after_destroy :remove_unused_tags

    private

    def remove_unused_tags
      if ActsAsTaggableOn.remove_unused_tags
        tag.destroy if tag.taggings_count.zero?
      end
    end
  end
end
