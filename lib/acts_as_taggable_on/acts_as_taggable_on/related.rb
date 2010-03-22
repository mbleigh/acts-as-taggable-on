module ActsAsTaggableOn::Taggable
  module Related
    def self.included(base)
      unless base.ancestors.include?(ActsAsTaggableOn::Taggable::Related::InstanceMethods)
        base.send :include, ActsAsTaggableOn::Taggable::Related::InstanceMethods
        base.extend ActsAsTaggableOn::Taggable::Related::ClassMethods
      end
      
      base.tag_types.map(&:to_s).each do |tag_type|
        base.class_eval %(
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
    
    module ClassMethods
    end
    
    module InstanceMethods
      def matching_contexts_for(search_context, result_context, klass, options = {})
        search_conditions = matching_context_search_options(search_context, result_context, klass, options)

        # klass.select(search_conditions[:select]).from(search_conditions[:from]).where(search_conditions[:conditions]).group(search_conditions[:group]).order(search_conditions[:order])
        klass.scoped(search_conditions)
      end

      def matching_context_search_options(search_context, result_context, klass, options = {})
        tags_to_find = tags_on(search_context).collect { |t| t.name }

        exclude_self = "#{klass.table_name}.id != #{id} AND" if self.class == klass

        { :select     => "#{klass.table_name}.*, COUNT(#{Tag.table_name}.id) AS count",
          :from       => "#{klass.table_name}, #{Tag.table_name}, #{Tagging.table_name}",
          :conditions => ["#{exclude_self} #{klass.table_name}.id = #{Tagging.table_name}.taggable_id AND #{Tagging.table_name}.taggable_type = '#{klass.to_s}' AND #{Tagging.table_name}.tag_id = #{Tag.table_name}.id AND #{Tag.table_name}.name IN (?) AND #{Tagging.table_name}.context = ?", tags_to_find, result_context],
          :group      => grouped_column_names_for(klass),
          :order      => "count DESC"
        }.update(options)
      end
      
      def related_tags_for(context, klass, options = {})
        search_conditions = related_search_options(context, klass, options)

        # klass.select(search_conditions[:select]).from(search_conditions[:from]).where(search_conditions[:conditions]).group(search_conditions[:group]).order(search_conditions[:order])
        klass.scoped(search_conditions)
      end

      def related_search_options(context, klass, options = {})
        tags_to_find = tags_on(context).collect { |t| t.name }

        exclude_self = "#{klass.table_name}.id != #{id} AND" if self.class == klass

        { :select     => "#{klass.table_name}.*, COUNT(#{Tag.table_name}.id) AS count",
          :from       => "#{klass.table_name}, #{Tag.table_name}, #{Tagging.table_name}",
          :conditions => ["#{exclude_self} #{klass.table_name}.id = #{Tagging.table_name}.taggable_id AND #{Tagging.table_name}.taggable_type = '#{klass.to_s}' AND #{Tagging.table_name}.tag_id = #{Tag.table_name}.id AND #{Tag.table_name}.name IN (?)", tags_to_find],
          :group      => grouped_column_names_for(klass),
          :order      => "count DESC"
        }.update(options)
      end
    end
  end
end