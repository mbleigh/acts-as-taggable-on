module ActsAsTaggableOn
  module Tagger
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      ##
      # Make a model a tagger. This allows an instance of a model to claim ownership
      # of tags.
      #
      # Example:
      #   class User < ActiveRecord::Base
      #     acts_as_tagger
      #   end
      def acts_as_tagger(opts={})
        class_eval do
          has_many_with_taggable_compatibility :owned_taggings,
                                               opts.merge(
                                                   as: :tagger,
                                                   dependent: :destroy,
                                                   class_name: '::ActsAsTaggableOn::Tagging'
                                               )

          has_many_with_taggable_compatibility :owned_tags,
                                               through: :owned_taggings,
                                               source: :tag,
                                               class_name: '::ActsAsTaggableOn::Tag',
                                               uniq: true
        end

        include ActsAsTaggableOn::Tagger::InstanceMethods
        extend ActsAsTaggableOn::Tagger::SingletonMethods
      end

      def tagger?
        false
      end

      def is_tagger?
        tagger?
      end
    end

    module InstanceMethods
      ##
      # Tag a taggable model with tags that are owned by the tagger.
      #
      # @param taggable The object that will be tagged
      # @param [Hash] options An hash with options. Available options are:
      #               * <tt>:with</tt> - The tags that you want to
      #               * <tt>:on</tt>   - The context on which you want to tag
      #
      # Example:
      #   @user.tag(@photo, :with => "paris, normandy", :on => :locations)
      def tag(taggable, opts={})
        opts.reverse_merge!(force: true)
        skip_save = opts.delete(:skip_save)
        return false unless taggable.respond_to?(:is_taggable?) && taggable.is_taggable?

        fail 'You need to specify a tag context using :on' unless opts.key?(:on)
        fail 'You need to specify some tags using :with' unless opts.key?(:with)
        fail "No context :#{opts[:on]} defined in #{taggable.class}" unless opts[:force] || taggable.tag_types.include?(opts[:on])

        taggable.set_owner_tag_list_on(self, opts[:on].to_s, opts[:with])
        taggable.save unless skip_save
      end

      def tagger?
        self.class.is_tagger?
      end

      def is_tagger?
        tagger?
      end
    end

    module SingletonMethods
      def tagger?
        true
      end

      def is_tagger?
        tagger?
      end
    end
  end
end
