module ActsAsTaggableOn::Taggable
  module Recommended
    def self.included(base)
      base.send :include, ActsAsTaggableOn::Taggable::Recommended::InstanceMethods
      base.extend ActsAsTaggableOn::Taggable::Recommended::ClassMethods
      base.initialize_acts_as_taggable_on_recommended
    end

    module ClassMethods
      def initialize_acts_as_taggable_on_recommended
        tag_types.map(&:to_s).each do |tag_type|
          class_eval %(
              def find_#{tag_type}_recommended_for(association_id, attribute_of_association, value)
                recommended_tags_for(self.class, association_id, attribute_of_association, value)
              end
          )
        end
      end

      def acts_as_taggable_on(*args)
        super(*args)
        initialize_acts_as_taggable_on_recommended
      end
    end

    module InstanceMethods
      def recommended_tags_for(klass, association_id, attribute_of_association, value)
        klass_association = self.send("#{association_id}").class
        
        ActsAsTaggableOn::Tag.scoped({ :select     => "#{ActsAsTaggableOn::Tag.table_name}.name, COUNT(#{ActsAsTaggableOn::Tag.table_name}.*) AS tag_counts",
                       :from       => "#{klass.table_name}, #{ActsAsTaggableOn::Tag.table_name}, #{ActsAsTaggableOn::Tagging.table_name}, #{klass_association.table_name}",
                       :conditions => ["#{ActsAsTaggableOn::Tagging.table_name}.taggable_type = '#{klass.to_s}' AND #{ActsAsTaggableOn::Tagging.table_name}.taggable_id = #{klass.table_name}.id AND #{klass_association.table_name}.#{attribute_of_association} = ? AND #{ActsAsTaggableOn::Tag.table_name}.id = #{ActsAsTaggableOn::Tagging.table_name}.tag_id", value],
                       :group => "#{ActsAsTaggableOn::Tag.table_name}.name HAVING COUNT(*) > 0",
                       :order      => "tag_counts DESC" })
      end
    end
  end
end
