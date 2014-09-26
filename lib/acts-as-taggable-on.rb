require 'active_record'
require 'active_record/version'
require 'active_support/core_ext/module'

require_relative 'acts_as_taggable_on/engine'  if defined?(Rails)

require 'digest/sha1'

module ActsAsTaggableOn
  extend ActiveSupport::Autoload

  autoload :Tag
  autoload :TagList
  autoload :GenericParser
  autoload :DefaultParser
  autoload :TagListParser
  autoload :Taggable
  autoload :Tagger
  autoload :Tagging
  autoload :TagsHelper
  autoload :VERSION

  autoload_under 'taggable' do
    autoload :Cache
    autoload :Collection
    autoload :Core
    autoload :Dirty
    autoload :Ownership
    autoload :Related
  end

  autoload :Utils
  autoload :Compatibility


  class DuplicateTagError < StandardError
  end

  def self.setup
    @configuration ||= Configuration.new
    yield @configuration if block_given?
  end

  def self.method_missing(method_name, *args, &block)
    @configuration.respond_to?(method_name) ?
        @configuration.send(method_name, *args, &block) : super
  end

  def self.respond_to?(method_name, include_private=false)
    @configuration.respond_to? method_name
  end

  def self.glue
    setting = @configuration.delimiter
    delimiter = setting.kind_of?(Array) ? setting[0] : setting
    delimiter.ends_with?(' ') ? delimiter : "#{delimiter} "
  end

  # Apply attributes/methods to app class (ex., class Student now responds_to `taggable?` and has_many :taggings)
  def self.tagify_class!(klass, namespace)
    klass.class_attribute :taggable_namespace
    klass.taggable_namespace = namespace
    # Join the namespace and base object name (i.e., Tagging > namespace_tagging) 
    ns = Proc.new { |obj| [*namespace, obj.to_s.underscore].join('_').to_sym }
    ns_class = Proc.new { |obj| "ActsAsTaggableOn::#{ ns.call(obj).to_s.camelize }" }

    klass.class_eval do
      # Namespace the relations
      # i.e., No namespace:             has_many :taggings, ..., class_name: 'ActsAsTaggableOn::Tagging'
      # With a namespace of 'nspaced':  has_many :nspaced_taggings, ..., class_name: 'ActsAsTaggableOn::NspacedTagging'

      has_many ns.call(:taggings), as: :taggable, dependent: :destroy, class_name: ns_class.call(:Tagging)
      has_many :base_tags, through: ns.call(:taggings), source: :tag, class_name: ns_class.call(:Tag)
      alias_method :taggings, ns.call(:taggings)

      def self.taggable?
        true
      end

      # Returns namespaced class constant (i.e., ActsAsTaggableOn::namespaced(:Tag) > ActsAsTaggableOn::NamespacedTag)
      def self.namespaced(obj)
        "ActsAsTaggableOn::#{ taggable_namespace.to_s.camelize }#{ obj.to_s.camelize }".constantize
      end
      def namespaced(obj); self.class.namespaced obj; end
    end
  end

  # only: can optionally namespace one class at a time (ex., ActsAsTaggableOn.namespace_classes! :nspace, only: :Tag)
  # useful in test suite when creating NspacedTag and NspacedTagging models
  def self.namespace_classes!(namespace, only: nil)
    return if namespace.nil?
    # Join the namespace and base object name (i.e., Tagging > namespace_tagging) 
    ns = Proc.new { |obj| [*namespace, obj.to_s.underscore].join('_').to_sym }
    # Camelize base class (i.e., :namespace_taging > NamespaceTagging)
    ns_class = Proc.new { |obj| ns.call(obj).to_s.camelize }
    # Fully scoped namespaced class (i.e., ActsAsTaggableOn::Tagging > ActsAsTaggableOn::NamespaceTagging)
    ns_full_class = Proc.new { |obj| "ActsAsTaggableOn::#{ ns_class.call(obj) }" }

    # Copy ActsAsTaggableOn::Tag to ActsAsTaggableOn::[Namespace]Tag (where [Namespace] is usually set by `taggable_on`)
    if only.nil? or only.to_s.downcase.to_sym == :tag
      unless ActsAsTaggableOn.const_defined?(ns_class.call(:Tag))
        ActsAsTaggableOn.const_set ns_class.call(:Tag), Class.new(ActsAsTaggableOn::Tag)
        ns_full_class.call(:Tag).constantize.class_eval do
          has_many ns.call(:taggings), dependent: :destroy, class_name: ns_full_class.call(:Tagging), foreign_key: :tag_id, inverse_of: ns.call(:tag)
          self.table_name = ns.call(:tags)
        end
      end
    end

    # Copy ActsAsTaggableOn::Tagging to ActsAsTaggableOn::[Namespace]Tagging (where [Namespace] is usually set by `taggable_on`)
    if only.nil? or only.to_s.downcase.to_sym == :tagging
      unless ActsAsTaggableOn.const_defined?(ns_class.call(:Tagging))
        ActsAsTaggableOn.const_set ns_class.call(:Tagging), Class.new(ActsAsTaggableOn::Tagging)
        ns_full_class.call(:Tagging).constantize.class_eval do
          belongs_to ns.call(:Tag), class_name: ns_full_class.call(:Tag), counter_cache: ActsAsTaggableOn.tags_counter, inverse_of: ns.call(:taggings)
          self.table_name = ns.call(:taggings)
          # For some reason validators aren't copied over...
          validates_uniqueness_of :tag_id, scope: [:taggable_type, :taggable_id, :context, :tagger_id, :tagger_type]
          # The calls to base_class screw up the way this gem records tagger_type, so we need to modify the scope
          scope :not_owned, -> { where(tagger_id: nil, tagger_type: ns_full_class.call(:Tagging)) }
        end
      end
    end
  end

  class Configuration
    attr_accessor :delimiter, :force_lowercase, :force_parameterize,
                  :strict_case_match, :remove_unused_tags, :default_parser,
                  :tags_counter

    def initialize
      @delimiter = ','
      @force_lowercase = false
      @force_parameterize = false
      @strict_case_match = false
      @remove_unused_tags = false
      @tags_counter = true
      @default_parser = DefaultParser
    end

    def delimiter=(string)
      ActiveRecord::Base.logger.warn <<WARNING
ActsAsTaggableOn.delimiter is deprecated \
and will be removed from v4.0+, use  \
a ActsAsTaggableOn.default_parser instead
WARNING
      @delimiter = string
    end
  end

  setup
end

ActiveSupport.on_load(:active_record) do
  extend ActsAsTaggableOn::Compatibility
  extend ActsAsTaggableOn::Taggable
  include ActsAsTaggableOn::Tagger
end
ActiveSupport.on_load(:action_view) do
  include ActsAsTaggableOn::TagsHelper
end
