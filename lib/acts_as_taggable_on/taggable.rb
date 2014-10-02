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
    def acts_as_taggable(options = {})
      acts_as_taggable_on :tags, options
    end

    ##
    # This is an alias for calling <tt>acts_as_ordered_taggable_on :tags</tt>.
    #
    # Example:
    #   class Book < ActiveRecord::Base
    #     acts_as_ordered_taggable
    #   end
    def acts_as_ordered_taggable(options = {})
      acts_as_ordered_taggable_on :tags, options
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
    def acts_as_taggable_on(*options)
      # tag_types, options = ActsAsTaggableOn::Utils.get_tag_types_and_options(options)
      taggable_on false, options
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
    def acts_as_ordered_taggable_on(*options)
      # tag_types, options = ActsAsTaggableOn::Utils.get_tag_types_and_options(options)
      taggable_on true, options
    end

    private

      # Make a model taggable on specified contexts
      # and optionally preserves the order in which tags are created
      #
      # Separate methods used above for backwards compatibility
      # so that the original acts_as_taggable_on method is unaffected
      # as it's not possible to add another argument to the method
      # without the tag_types being enclosed in square brackets
      #
      # NB: method overridden in core module in order to create tag type
      #     associations and methods after this logic has executed
      #
    def taggable_on(preserve_tag_order, *options)
      tag_types, opts = ActsAsTaggableOn::Utils.get_tag_types_and_options(options)
      tag_types = tag_types.compact.map(&:to_sym)

      if taggable?
        self.tag_types = (self.tag_types + tag_types).uniq
        self.preserve_tag_order = preserve_tag_order
      else
        class_attribute :tag_types
        self.tag_types = tag_types
        class_attribute :preserve_tag_order
        self.preserve_tag_order = preserve_tag_order
        
        ns = opts.delete(:namespace)
        ActsAsTaggableOn.namespace_base_classes! ns
        ActsAsTaggableOn.tagify_class! self, ns
      end

      # each of these add context-specific methods and must be
      # called on each call of taggable_on
      include Core
      include Collection
      include Cache
      include Ownership
      include Related
      include Dirty
    end
  end
end
