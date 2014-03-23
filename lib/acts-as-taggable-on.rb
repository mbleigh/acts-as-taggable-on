require "active_record"
require "active_record/version"
require "active_support/core_ext/module"
require "action_view"

require "digest/sha1"

module ActsAsTaggableOn
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
    delimiter.ends_with?(" ") ? delimiter : "#{delimiter} "
  end

  class Configuration
    attr_accessor :delimiter, :force_lowercase, :force_parameterize,
      :strict_case_match, :remove_unused_tags

    def initialize
      @delimiter = ','
      @force_lowercase = false
      @force_parameterize = false
      @strict_case_match = false
      @remove_unused_tags = false
    end
  end

  setup
end


require "acts_as_taggable_on/utils"

require "acts_as_taggable_on/taggable"
require "acts_as_taggable_on/acts_as_taggable_on/compatibility"
require "acts_as_taggable_on/acts_as_taggable_on/core"
require "acts_as_taggable_on/acts_as_taggable_on/collection"
require "acts_as_taggable_on/acts_as_taggable_on/cache"
require "acts_as_taggable_on/acts_as_taggable_on/ownership"
require "acts_as_taggable_on/acts_as_taggable_on/related"
require "acts_as_taggable_on/acts_as_taggable_on/dirty"

require "acts_as_taggable_on/tagger"
require "acts_as_taggable_on/tag"
require "acts_as_taggable_on/tag_list"
require "acts_as_taggable_on/tags_helper"
require "acts_as_taggable_on/tagging"
require 'acts_as_taggable_on/engine'

ActiveSupport.on_load(:active_record) do
  extend ActsAsTaggableOn::Compatibility
  extend ActsAsTaggableOn::Taggable
  include ActsAsTaggableOn::Tagger
end
ActiveSupport.on_load(:action_view) do
  include ActsAsTaggableOn::TagsHelper
end
