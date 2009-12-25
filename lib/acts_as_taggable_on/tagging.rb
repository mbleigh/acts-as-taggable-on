class Tagging < ActiveRecord::Base #:nodoc:
  belongs_to :tag
  belongs_to :taggable, :polymorphic => true
  belongs_to :tagger, :polymorphic => true
  
  validates_presence_of :context
  validates_presence_of :tag_id
  
  validates_uniqueness_of :tag_id, :scope => [:taggable_type, :taggable_id, :context]
end