module ActsAsTaggableOn
  class Tagging < ::ActiveRecord::Base #:nodoc:
    DEFAULT_CONTEXT = 'tags'
    belongs_to :tag, class_name: '::ActsAsTaggableOn::Tag', counter_cache: ActsAsTaggableOn.tags_counter
    belongs_to :taggable, polymorphic: true

    belongs_to :tagger, {polymorphic: true}.tap {|o| o.merge!(optional: true) if ActsAsTaggableOn::Utils.active_record5? }

    scope :owned_by, ->(owner) { where(tagger: owner) }
    scope :not_owned, -> { where(tagger_id: nil, tagger_type: nil) }

    scope :by_contexts, ->(contexts) { where(context: (contexts || DEFAULT_CONTEXT)) }
    scope :by_context, ->(context = DEFAULT_CONTEXT) { by_contexts(context.to_s) }

    validates_presence_of :context
    validates_presence_of :tag_id

    validates_uniqueness_of :tag_id, scope: [:taggable_type, :taggable_id, :context, :tagger_id, :tagger_type]

    after_destroy :remove_unused_tags

    private

    def remove_unused_tags
      if ActsAsTaggableOn.remove_unused_tags
        if ActsAsTaggableOn.tags_counter
          tag.destroy if tag.reload.taggings_count.zero?
        else
          tag.destroy if tag.reload.taggings.count.zero?
        end
      end
    end
  end
end
