require "active_record"
require "active_record/version"
require "action_view"

require "digest/sha1"

$LOAD_PATH.unshift(File.dirname(__FILE__))

module ActsAsTaggableOn
  mattr_accessor :delimiter
  @@delimiter = ','

  mattr_accessor :force_lowercase
  @@force_lowercase = false

  mattr_accessor :force_parameterize
  @@force_parameterize = false

  mattr_accessor :strict_case_match
  @@strict_case_match = false

  mattr_accessor :remove_unused_tags
  self.remove_unused_tags = false

  def self.glue
    delimiter = @@delimiter.kind_of?(Array) ? @@delimiter[0] : @@delimiter
    delimiter.ends_with?(" ") ? delimiter : "#{delimiter} "
  end

  def self.setup
    yield self
  end
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

$LOAD_PATH.shift


if defined?(ActiveRecord::Base)
  ActiveRecord::Base.extend ActsAsTaggableOn::Compatibility
  ActiveRecord::Base.extend ActsAsTaggableOn::Taggable
  ActiveRecord::Base.send :include, ActsAsTaggableOn::Tagger
end

if defined?(ActionView::Base)
  ActionView::Base.send :include, ActsAsTaggableOn::TagsHelper
end

