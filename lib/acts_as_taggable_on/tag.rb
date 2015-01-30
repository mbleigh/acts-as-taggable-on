# encoding: utf-8
module ActsAsTaggableOn
  class Tag < BasicTag
    self.table_name = :tags
    self.superclass.table_name = :tags

    has_many :taggings, dependent: :destroy, class_name: 'ActsAsTaggableOn::Tagging', inverse_of: :tag

    validates_presence_of :name
    validates_uniqueness_of :name, if: :validates_name_uniqueness?
    validates_length_of :name, maximum: 255
  end
end
