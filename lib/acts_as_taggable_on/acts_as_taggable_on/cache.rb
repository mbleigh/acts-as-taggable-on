module ActsAsTaggableOn::Taggable
  module Cache
    def self.included(base)
      base.class_eval do
        before_save :save_cached_tag_list        
      end
      
      base.tag_types.map(&:to_s).each do |tag_type|
        base.class_eval %(
          def self.caching_#{tag_type.singularize}_list?
            caching_tag_list_on?("#{tag_type}")
          end        
        )
      end
      
      base.extend ClassMethods
      include InstanceMethods
    end
    
    module ClassMethods
      def caching_tag_list_on?(context)
        column_names.include?("cached_#{context.to_s.singularize}_list")
      end
    end
    
    module InstanceMethods
      def cached_tag_list_on(context)
        self["cached_#{context.to_s.singularize}_list"]
      end

      def tag_list_cache_on(context)
        variable_name = "@#{context.to_s.singularize}_list"
        cache = instance_variable_get(variable_name)
        instance_variable_set(variable_name, cache = {}) unless cache
        cache
      end
      
      def save_cached_tag_list
        self.class.tag_types.map(&:to_s).each do |tag_type|
          if self.class.send("caching_#{tag_type.singularize}_list?")
            self["cached_#{tag_type.singularize}_list"] = tag_list_cache_on(tag_type.singularize).to_a.flatten.compact.join(', ')
          end
        end
      end
    end
  end
end