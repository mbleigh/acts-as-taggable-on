module ActsAsTaggableOn
  module Taggable
    def taggable?
      false
    end

    def acts_as_taggable
      acts_as_taggable_on :tags
    end

    def acts_as_taggable_on(*tag_types)
      tag_types = tag_types.to_a.flatten.compact.map(&:to_sym)

      if taggable?
        write_inheritable_attribute(:tag_types, (self.tag_types + tag_types).uniq)
      else
        if ::ActiveRecord::VERSION::MAJOR < 3
          include ActsAsTaggableOn::ActiveRecord::Backports
        end

        write_inheritable_attribute(:tag_types, tag_types)
        class_inheritable_reader(:tag_types)
        
        class_eval do
          has_many :taggings, :as => :taggable, :dependent => :destroy, :include => :tag
          has_many :base_tags, :class_name => "Tag", :through => :taggings, :source => :tag

          def self.taggable?
            true
          end
        
          include ActsAsTaggableOn::Taggable::Core
          include ActsAsTaggableOn::Taggable::Collection
          include ActsAsTaggableOn::Taggable::Cache
          include ActsAsTaggableOn::Taggable::Ownership
          include ActsAsTaggableOn::Taggable::Related
        end
      end
    end
  end
end
