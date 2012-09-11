module ActsAsTaggableOn
  module Taggable
    def taggable?
      false
    end

    ##
    # This is an alias for calling <tt>acts_as_taggable_on :tags</tt>.
    #
    # Example:
    #   class Book < ActiveRecord::Base
    #     acts_as_taggable
    #   end
    def acts_as_taggable
      acts_as_taggable_on :tags
    end

    ##
    # This is an alias for calling <tt>acts_as_ordered_taggable_on :tags</tt>.
    #
    # Example:
    #   class Book < ActiveRecord::Base
    #     acts_as_ordered_taggable
    #   end
    def acts_as_ordered_taggable
      acts_as_ordered_taggable_on :tags
    end
    
    ##
    # Make a model taggable on specified contexts.
    #
    # @param [Array] tag_types An array of taggable contexts
    #
    # Example:
    #   class User < ActiveRecord::Base
    #     acts_as_taggable_on :languages, :skills
    #   end
    def acts_as_taggable_on(*tag_types)
      taggable_on(false, tag_types)
    end
    
    
    ##
    # Make a model taggable on specified contexts
    # and preserves the order in which tags are created
    #
    # @param [Array] tag_types An array of taggable contexts
    #
    # Example:
    #   class User < ActiveRecord::Base
    #     acts_as_ordered_taggable_on :languages, :skills
    #   end
    def acts_as_ordered_taggable_on(*tag_types)
      taggable_on(true, tag_types)
    end
    
    #
    # Set the base class used for tagging
    # If you change that, you have to subclass it from
    # ActsAsTaggableOn::Tagging
    #
    def set_tagging_class(klass)
      class_attribute :tagging_class
      self.tagging_class = klass
    end


    def set_tag_class(klass)
      class_attribute :tag_class
      self.tag_class = klass
    end

    private
    
      # Make a model taggable on specified contexts
      # and optionally preserves the order in which tags are created
      #
      # Seperate methods used above for backwards compatibility
      # so that the original acts_as_taggable_on method is unaffected
      # as it's not possible to add another arguement to the method
      # without the tag_types being enclosed in square brackets
      #
      # NB: method overridden in core module in order to create tag type
      #     associations and methods after this logic has executed
      #
      def taggable_on(preserve_tag_order, *tag_types)
        
        unless respond_to?(:tagging_class) && tagging_class
          set_tagging_class("ActsAsTaggableOn::Tagging")
        end
        unless respond_to?(:tag_class) && tag_class
          set_tag_class("ActsAsTaggableOn::Tag")
        end
        
        class_attribute :tag_type_options unless respond_to?(:tag_type_options)
        self.tag_type_options ||= {}
        extract_tag_type_options!(tag_types)
       
        if taggable?
          self.tag_types = (self.tag_types + tag_types).uniq
          self.preserve_tag_order = preserve_tag_order
        else
          class_attribute :tag_types
          self.tag_types = tag_types
          class_attribute :preserve_tag_order
          self.preserve_tag_order = preserve_tag_order
        
 
          class_eval do

            def self.taggable?
              true
            end

            include ActsAsTaggableOn::Utils
            include ActsAsTaggableOn::Taggable::Core
            include ActsAsTaggableOn::Taggable::Collection
            include ActsAsTaggableOn::Taggable::Cache
            include ActsAsTaggableOn::Taggable::Ownership
            include ActsAsTaggableOn::Taggable::Related
            include ActsAsTaggableOn::Taggable::Dirty
          end
        end
        prepare_tag_class!
        prepare_tagging_class!
      end


      def extract_tag_type_options!(tag_types)
        tag_types.flatten!
        tag_types.compact!
        tag_types.map! {|tt|
          if tt.kind_of?(Hash)
            tag_type_options[tt.keys.first] = tt.values.first
            tt.keys.first              
          else
            tt
          end
          }
      end
      
      def prepare_tag_class!
        tag_class.constantize.tagging_class = self.tagging_class
      end

      def prepare_tagging_class!
        tagging_class.constantize.tag_class = self.tag_class
      end

  end
end
