# WIP: dirty attributes support for tags
module ActsAsTaggableOn::Taggable
  module Dirty
    def self.included(base)
      include ActsAsTaggableOn::Taggable::Dirty::InstanceMethods

      base.tag_types.map(&:to_s).each do |tag_type|
        base.class_eval %(
          def #{tag_type.singularize}_list_changed?
            tag_list_changed_on?('#{tag_type}')
            tag_list_on('#{tag_type}')
          end

          def #{tag_type.singularize}_list=(new_tags)
            change_tag_list_on('#{tag_type}', new_tags)
            super(new_tags)
          end
        )
      end      
    end
    
    module InstanceMethods
      def tag_list_changed_on?(context)
      end
      
      def change_tag_list_on(context, new_tags)        
      end
    end
  end
end