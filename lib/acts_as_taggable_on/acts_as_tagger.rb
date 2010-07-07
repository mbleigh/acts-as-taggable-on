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
          has_many :owned_taggings, opts.merge(:as => :tagger, :dependent => :destroy,
                                               :include => :tag, :class_name => "ActsAsTaggableOn::Tagging")
          has_many :owned_tags, :through => :owned_taggings, :source => :tag, :uniq => true, :class_name => "ActsAsTaggableOn::Tag"
        end

        include ActsAsTaggableOn::Tagger::InstanceMethods
        extend ActsAsTaggableOn::Tagger::SingletonMethods
      end

      def is_tagger?
        false
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
        opts.reverse_merge!(:force => true)

        return false unless taggable.respond_to?(:is_taggable?) && taggable.is_taggable?

        raise "You need to specify a tag context using :on"                unless opts.has_key?(:on)
        raise "You need to specify some tags using :with"                  unless opts.has_key?(:with)
        raise "No context :#{opts[:on]} defined in #{taggable.class.to_s}" unless (opts[:force] || taggable.tag_types.include?(opts[:on]))

        taggable.set_owner_tag_list_on(self, opts[:on].to_s, opts[:with])
        taggable.save
      end

      def is_tagger?
        self.class.is_tagger?
      end
    end

    module SingletonMethods
      def is_tagger?
        true
      end
    end
  end
end
