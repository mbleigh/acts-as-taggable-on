module ActsAsTaggableOn
  class Tagging < BasicTagging
    self.table_name = :taggings
    self.superclass.table_name = :taggings

    attr_accessible :tag, :tag_id if defined?(ActiveModel::MassAssignmentSecurity)
    
    belongs_to :tag, class_name: 'ActsAsTaggableOn::Tag', counter_cache: ActsAsTaggableOn.tags_counter, inverse_of: :taggings

    validates_presence_of :tag_id
    validates_uniqueness_of :tag_id, scope: [:taggable_type, :taggable_id, :context, :tagger_id, :tagger_type]
    validates_presence_of :context
  end
end
