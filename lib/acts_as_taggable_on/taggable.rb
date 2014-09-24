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
    def acts_as_taggable(**named_args)
      acts_as_taggable_on :tags, **named_args
    end

    ##
    # This is an alias for calling <tt>acts_as_ordered_taggable_on :tags</tt>.
    #
    # Example:
    #   class Book < ActiveRecord::Base
    #     acts_as_ordered_taggable
    #   end
    def acts_as_ordered_taggable(**named_args)
      acts_as_ordered_taggable_on :tags, **named_args
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
    def acts_as_taggable_on(*tag_types, **named_args)
      taggable_on false, *tag_types, **named_args
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
    def acts_as_ordered_taggable_on(*tag_types, **named_args)
      taggable_on true, *tag_types, **named_args
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
    def taggable_on(preserve_tag_order, *tag_types, **named_args)
      tag_types = tag_types.to_a.flatten.compact.map(&:to_sym)
      namespace = named_args.delete(:namespace)

      if taggable?
        self.tag_types = (self.tag_types + tag_types).uniq
        self.preserve_tag_order = preserve_tag_order
      else
        class_attribute :tag_types
        self.tag_types = tag_types
        class_attribute :preserve_tag_order
        self.preserve_tag_order = preserve_tag_order

        # Dynamic namespace prepender (ex., taggings > namespaced_taggings)
        # If no namespace exists, it defaults to the original
        ns = Proc.new { |obj| [*namespace, obj].join('_') }
        ns_class = Proc.new { |obj| "ActsAsTaggableOn::#{ ns.call(obj).camelize }" }

        # Dynamically create namespaced versions of base classes.
        # For example, assume namespace = "Namespaced"
        # Namespaced classes fully inherit their respective base classes but modify their relations
        # for the presence of a namespace.
        unless namespace.nil?

          # ActsAsTaggableOn::Tag > ActsAsTaggableOn::NamespacedTag
          c = Class.new(ActsAsTaggableOn::Tag) do
            has_many :taggings, dependent: :destroy, class_name: ns_class.call(:tagging)
            self.table_name = ns.call(:tags).to_sym
          end
          ActsAsTaggableOn.const_set ns.call(:tag).camelize.to_s, c

          # ActsAsTaggableOn::Tagging > ActsAsTaggableOn::NamespacedTagging
          c = Class.new(ActsAsTaggableOn::Tagging) do
            # belongs_to ns.call(:tag).to_sym, class_name: ns_class.call(:tag), counter_cache: ActsAsTaggableOn.tags_counter
            belongs_to :tag, class_name: ns_class.call(:tag)
            self.table_name = ns.call(:taggings).to_sym
          end
          ActsAsTaggableOn.const_set ns.call(:tagging).camelize.to_s, c

          c = nil

        end

        class_eval do
          # Namespace the relations if necessary
          # i.e., No namespace:             has_many :taggings, ..., class_name: 'ActsAsTaggableOn::Tagging'
          # With a namespace of 'nspaced':  has_many :nspaced_taggings, ..., class_name: 'ActsAsTaggableOn::NspacedTagging'

          has_many ns.call(:taggings).to_sym, as: :taggable, dependent: :destroy, class_name: ns_class.call(:tagging)
          has_many :base_tags, through: ns.call(:taggings).to_sym, source: :tag, class_name: ns_class.call(:tag)
          alias_method :taggings, ns.call(:taggings).to_sym

          @tag_namespace = namespace

          def self.taggable?
            true
          end
          def self.tag_namespaced(obj)
            "ActsAsTaggableOn::#{ @tag_namespace.to_s.camelize }#{ obj.to_s.camelize }".constantize
          end
          def tag_namespaced(obj); self.class.tag_namespaced obj; end
        end
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
