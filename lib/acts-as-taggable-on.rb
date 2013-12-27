require "active_record"
require "active_record/version"
require "active_support/core_ext/module"
require "action_view"
require 'active_support/all'

require "digest/sha1"

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

require "acts_as_taggable_on/acts_as_taggable_on/core"
require "acts_as_taggable_on/acts_as_taggable_on/collection"
require "acts_as_taggable_on/acts_as_taggable_on/cache"
require "acts_as_taggable_on/acts_as_taggable_on/ownership"
require "acts_as_taggable_on/acts_as_taggable_on/related"
require "acts_as_taggable_on/acts_as_taggable_on/dirty"

require "acts_as_taggable_on/tag"
require "acts_as_taggable_on/tag_list"
require "acts_as_taggable_on/tagging"
require 'acts_as_taggable_on/rails_ext'
