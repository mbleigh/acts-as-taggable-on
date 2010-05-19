module ActsAsTaggableOn::Taggable
  module Related
    def self.included(base)
      base.send :include, ActsAsTaggableOn::Taggable::Related::InstanceMethods
      base.extend ActsAsTaggableOn::Taggable::Related::ClassMethods
      base.initialize_acts_as_taggable_on_related
    end
    
    module ClassMethods
      def initialize_acts_as_taggable_on_related
        tag_types.map(&:to_s).each do |tag_type|
          class_eval %(
            def find_related_#{tag_type}(options = {})
              related_tags_for('#{tag_type}', self.class, options)
            end
            alias_method :find_related_on_#{tag_type}, :find_related_#{tag_type}

            def find_related_#{tag_type}_for(klass, options = {})
              related_tags_for('#{tag_type}', klass, options)
            end

            def find_matching_contexts(search_context, result_context, options = {})
              matching_contexts_for(search_context.to_s, result_context.to_s, self.class, options)
            end

            def find_matching_contexts_for(klass, search_context, result_context, options = {})
              matching_contexts_for(search_context.to_s, result_context.to_s, klass, options)
            end
          )
        end        
      end
      
      def acts_as_taggable_on(*args)
        super(*args)
        initialize_acts_as_taggable_on_related
      end
    end
    
    module InstanceMethods
      def matching_contexts_for(search_context, result_context, klass, options = {})
        tags_to_find = tags_on(search_context).collect { |t| t.name }

        exclude_self = "#{klass.table_name}.id != #{id} AND" if self.class == klass
        
        group_columns = ActsAsTaggableOn::Tag.using_postgresql? ? grouped_column_names_for(klass) : "#{klass.table_name}.#{klass.primary_key}"
        
        klass.scoped({ :select     => "#{klass.table_name}.*, COUNT(#{ActsAsTaggableOn::Tag.table_name}.id) AS count",
                       :from       => "#{klass.table_name}, #{ActsAsTaggableOn::Tag.table_name}, #{ActsAsTaggableOn::Tagging.table_name}",
                       :conditions => ["#{exclude_self} #{klass.table_name}.id = #{ActsAsTaggableOn::Tagging.table_name}.taggable_id AND #{ActsAsTaggableOn::Tagging.table_name}.taggable_type = '#{klass.to_s}' AND #{ActsAsTaggableOn::Tagging.table_name}.tag_id = #{ActsAsTaggableOn::Tag.table_name}.id AND #{ActsAsTaggableOn::Tag.table_name}.name IN (?) AND #{ActsAsTaggableOn::Tagging.table_name}.context = ?", tags_to_find, result_context],
                       :group      => group_columns,
                       :order      => "count DESC" }.update(options))
      end
      
      def related_tags_for(context, klass, options = {})
        tags_to_find = tags_on(context).collect { |t| t.name }

        exclude_self = "#{klass.table_name}.id != #{id} AND" if self.class == klass

group_columns = ActsAsTaggableOn::Tag.using_postgresql? ? grouped_column_names_for(klass) : "#{klass.table_name}.#{klass.primary_key}"

        klass.scoped({ :select     => "#{klass.table_name}.*, COUNT(#{ActsAsTaggableOn::Tag.table_name}.id) AS count",
                       :from       => "#{klass.table_name}, #{ActsAsTaggableOn::Tag.table_name}, #{ActsAsTaggableOn::Tagging.table_name}",
                       :conditions => ["#{exclude_self} #{klass.table_name}.id = #{ActsAsTaggableOn::Tagging.table_name}.taggable_id AND #{ActsAsTaggableOn::Tagging.table_name}.taggable_type = '#{klass.to_s}' AND #{ActsAsTaggableOn::Tagging.table_name}.tag_id = #{ActsAsTaggableOn::Tag.table_name}.id AND #{ActsAsTaggableOn::Tag.table_name}.name IN (?)", tags_to_find],
                       :group      => group_columns,
                       :order      => "count DESC" }.update(options))
      end
    end
  end
end