require 'active_record'
require 'active_record/version'
require 'active_support/core_ext/module'

require_relative 'acts_as_taggable_on/engine' if defined?(Rails)

require 'digest/sha1'

module ActsAsTaggableOn
  extend ActiveSupport::Autoload

  autoload :BasicTag
  autoload :BasicTagging
  autoload :Tag
  autoload :TagList
  autoload :GenericParser
  autoload :DefaultParser
  autoload :Migrator
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




  # Returns namespaced class constant (i.e., ActsAsTaggableOn::namespaced(:Tag) > ActsAsTaggableOn::NamespacedTag)
  def self.namespaced_class(ns, obj, options = {as_constant: true})
    m = "ActsAsTaggableOn::#{ ns.to_s.camelize }#{ obj.to_s.camelize }"
    options[:as_constant] ? m.constantize : m
  end

  def self.namespaced_attribute(ns, att)
    [*ns, att].join('_').to_sym
  end

  # Allow affected model/instance to namespace attributes and classes
  # i.e., Tag > NspacedTag (namespaced),
  #       tag > nspaced_tag (namespaced_class)
  def self.add_namespace_class_helpers!(klass)
    klass.class_eval do
      def self.namespaced(att)
        ActsAsTaggableOn.namespaced_attribute taggable_on_namespace, att
      end

      def self.namespaced_class(obj, options = {as_constant: true})
        ActsAsTaggableOn.namespaced_class taggable_on_namespace, obj, options
      end

      def namespaced(att); self.class.namespaced att; end
      def namespaced_class(obj, options = {as_constant: true}); self.class.namespaced_class obj, options; end
    end
  end

  # Apply attributes/methods to app class (ex., class Student now responds_to `taggable?` and has_many :taggings)
  def self.tagify_class!(klass, namespace)
    klass.class_attribute :taggable_on_namespace
    klass.taggable_on_namespace = namespace

    # Shortcuts
    ns = ->(obj) { ActsAsTaggableOn.namespaced_attribute namespace, obj }
    ns_class = ->(obj, as_constant=true) { ActsAsTaggableOn.namespaced_class namespace, obj, as_constant: as_constant }

    ActsAsTaggableOn.add_namespace_class_helpers! klass
    klass.class_eval do
      # Namespace the relations
      # i.e., No namespace:             has_many :taggings, ..., class_name: 'ActsAsTaggableOn::Tagging'
      # With a namespace of 'nspaced':  has_many :nspaced_taggings, ..., class_name: 'ActsAsTaggableOn::NspacedTagging'
      has_many ns.call(:taggings), as: :taggable, dependent: :destroy, class_name: ns_class.call(:Tagging, false)
      has_many :base_tags, through: ns.call(:taggings), source: ns.call(:tag), class_name: ns_class.call(:Tag, false)
      alias_method :taggings, ns.call(:taggings)

      def self.taggable?
        true
      end
    end
  end

  # only: can optionally namespace one class at a time (ex., ActsAsTaggableOn.namespace_classes! :nspace, only: :Tag)
  # useful in test suite when creating NspacedTag and NspacedTagging models
  def self.namespace_base_classes!(namespace, options = {only: nil})
    return if namespace.nil?
    only = options[:only]

    # Shortcuts
    ns = ->(obj) { ActsAsTaggableOn.namespaced_attribute namespace, obj }
    ns_class = ->(obj, as_constant=true) { ActsAsTaggableOn.namespaced_class namespace, obj, as_constant: as_constant }
    # Namespaced class without the ActsAsTaggableOn module prefix and in string format
    ns_base_class = ->(obj) { ActsAsTaggableOn.namespaced_class(namespace, obj, as_constant: false).demodulize }

    # Copy ActsAsTaggableOn::Tag to ActsAsTaggableOn::[Namespace]Tag (where [Namespace] is usually set by `taggable_on`)
    if only.nil? or only.to_s.downcase.to_sym == :tag
      unless ActsAsTaggableOn.const_defined?(ns_base_class.call(:Tag))
        ActsAsTaggableOn.const_set ns_base_class.call(:Tag), Class.new(ActsAsTaggableOn::BasicTag)
        klass = ns_class.call(:Tag)
        klass.taggable_on_namespace = namespace
        klass.class_eval do
          self.table_name = ns.call(:tags)
          self.superclass.table_name = ns.call(:tags)

          has_many ns.call(:taggings), dependent: :destroy, class_name: ns_class.call(:Tagging, false), foreign_key: ns.call(:tag_id), inverse_of: ns.call(:tag)

          validates_presence_of :name
          validates_uniqueness_of :name, if: :validates_name_uniqueness?
          validates_length_of :name, maximum: 255

          # Override normal attribute getters/setters
          define_method(:taggings_count) do
            send ns.call(:taggings_count)
          end
        end
      end
    end

    # Copy ActsAsTaggableOn::Tagging to ActsAsTaggableOn::[Namespace]Tagging (where [Namespace] is usually set by `taggable_on`)
    if only.nil? or only.to_s.downcase.to_sym == :tagging
      unless ActsAsTaggableOn.const_defined?(ns_base_class.call(:Tagging))
        ActsAsTaggableOn.const_set ns_base_class.call(:Tagging), Class.new(ActsAsTaggableOn::BasicTagging)
        klass = ns_class.call(:Tagging)
        klass.taggable_on_namespace = namespace
        klass.class_eval do
          self.table_name = ns.call(:taggings)
          self.superclass.table_name = ns.call(:taggings)

          belongs_to ns.call(:tag), class_name: ns_class.call(:Tag, false), counter_cache: ActsAsTaggableOn.tags_counter, inverse_of: ns.call(:taggings)
          
          # For some reason validators aren't copied over...
          validates_presence_of ns.call(:tag_id)
          validates_uniqueness_of ns.call(:tag_id), scope: [:taggable_type, :taggable_id, :context, :tagger_id, :tagger_type]
          validates_presence_of :context

          # Override normal attribute getters/setters
          define_method(:tag) do
            send ns.call(:tag)
          end
          define_method(:tag=) do |val|
            send ns.call(:tag=), val
          end
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
