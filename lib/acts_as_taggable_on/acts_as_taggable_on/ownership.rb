module ActsAsTaggableOn::Taggable
  module Ownership
    def self.included(base)
      base.send :include, ActsAsTaggableOn::Taggable::Ownership::InstanceMethods
      base.extend ActsAsTaggableOn::Taggable::Ownership::ClassMethods
     
      base.class_eval do
        after_save :save_owned_tags    
      end
      
      base.initialize_acts_as_taggable_on_ownership
    end
    
    module ClassMethods
      def acts_as_taggable_on(*args)
        initialize_acts_as_taggable_on_ownership
        super(*args)
      end
      
      def initialize_acts_as_taggable_on_ownership      
        tag_types.map(&:to_s).each do |tag_type|
          class_eval %(
            def #{tag_type}_from(owner)
              owner_tag_list_on(owner, '#{tag_type}')
            end      
          )
        end        
      end
    end
    
    module InstanceMethods
      def owner_tags_on(owner, context)
        if owner.nil?
          scope = base_tags.where([%(#{ActsAsTaggableOn::Tagging.table_name}.context = ?), context.to_s])                    
        else
          scope = base_tags.where([%(#{ActsAsTaggableOn::Tagging.table_name}.context = ? AND
                                     #{ActsAsTaggableOn::Tagging.table_name}.tagger_id = ? AND
                                     #{ActsAsTaggableOn::Tagging.table_name}.tagger_type = ?), context.to_s, owner.id, owner.class.base_class.to_s])          
        end
        # when preserving tag order, return tags in created order
        # if we added the order to the association this would always apply
        scope = scope.order("#{ActsAsTaggableOn::Tagging.table_name}.id") if self.class.preserve_tag_order?
        scope.all
      end

      def cached_owned_tag_list_on(context)
        variable_name = "@owned_#{context}_list"
        cache = instance_variable_get(variable_name) || instance_variable_set(variable_name, {})
      end
      
      def owner_tag_list_on(owner, context)
        add_custom_context(context)

        cache = cached_owned_tag_list_on(context)
        cache.delete_if { |key, value| key.id == owner.id && key.class == owner.class }
        
        cache[owner] ||= ActsAsTaggableOn::TagList.new(*owner_tags_on(owner, context).map(&:name))
      end
      
      def set_owner_tag_list_on(owner, context, new_list)
        add_custom_context(context)
        
        cache = cached_owned_tag_list_on(context)
        cache.delete_if { |key, value| key.id == owner.id && key.class == owner.class }

        cache[owner] = ActsAsTaggableOn::TagList.from(new_list)
      end
      
      def reload(*args)
        self.class.tag_types.each do |context|
          instance_variable_set("@owned_#{context}_list", nil)
        end
      
        super(*args)
      end
    
      def save_owned_tags
        tagging_contexts.each do |context|
          cached_owned_tag_list_on(context).each do |owner, tag_list|
            
            # Find existing tags or create non-existing tags:
            tags = ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(tag_list.uniq)            

            # Tag objects for owned tags
            owned_tags = owner_tags_on(owner, context)
               
            # Tag maintenance based on whether preserving the created order of tags
            if self.class.preserve_tag_order?
              # First off order the array of tag objects to match the tag list
              # rather than existing tags followed by new tags
              tags = tag_list.uniq.map{|s| tags.detect{|t| t.name.downcase == s.downcase}}
              # To preserve tags in the order in which they were added
              # delete all owned tags and create new tags if the content or order has changed
              old_tags = (tags == owned_tags ? [] : owned_tags)
              new_tags = (tags == owned_tags ? [] : tags)
            else
              # Delete discarded tags and create new tags
              old_tags = owned_tags - tags
              new_tags = tags - owned_tags
            end
          
            # Find all taggings that belong to the taggable (self), are owned by the owner, 
            # have the correct context, and are removed from the list.
            if old_tags.present?
              old_taggings = ActsAsTaggableOn::Tagging.where(:taggable_id => id, :taggable_type => self.class.base_class.to_s,
                                                             :tagger_type => owner.class.base_class.to_s, :tagger_id => owner.id,
                                                             :tag_id => old_tags, :context => context).all
            end
          
            # Destroy old taggings:
            if old_taggings.present?
              ActsAsTaggableOn::Tagging.destroy_all(:id => old_taggings.map(&:id))
            end

            # Create new taggings:
            new_tags.each do |tag|
              taggings.create!(:tag_id => tag.id, :context => context.to_s, :tagger => owner, :taggable => self)
            end
          end
        end
        
        true
      end
    end
  end
end
