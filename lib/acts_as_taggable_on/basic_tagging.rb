module ActsAsTaggableOn
  class BasicTagging < ::ActiveRecord::Base #:nodoc:
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

    class_attribute :taggable_on_namespace
    ActsAsTaggableOn.add_namespace_class_helpers! self
    
    belongs_to :taggable, polymorphic: true
    belongs_to :tagger,   polymorphic: true

    scope :owned_by, ->(owner) { where(tagger: owner) }
    scope :not_owned, -> { where(tagger_id: nil, tagger_type: nil) }

    scope :by_contexts, ->(contexts = ['tags']) { where(context: contexts) }
    scope :by_context, ->(context= 'tags') { by_contexts(context.to_s) }

    after_destroy :remove_unused_tags
    

    private


    def remove_unused_tags
      if ActsAsTaggableOn.remove_unused_tags
        # The same outcome...???
        if ActsAsTaggableOn.tags_counter
          tag.destroy if tag.reload.taggings_count.zero? rescue true
        else
          tag.destroy if tag.reload.taggings.count.zero? rescue true
        end
      end
    end
  end
end
