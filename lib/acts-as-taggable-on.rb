require "active_record"
require "active_record/version"
require "action_view"
require 'active_support/all'

require "digest/sha1"

module ActsAsTaggableOn
  include ActiveSupport::Configurable

  config_accessor(:delimiter)           { ',' }
  config_accessor(:force_lowercase)    { false }
  config_accessor(:force_parameterize) { false }
  config_accessor(:strict_case_match)  { false }
  config_accessor(:remove_unused_tags) { false }

  def self.glue
    del = delimiter.kind_of?(Array) ? delimiter[0] : delimiter
    del.ends_with?(" ") ? del : "#{del} "
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

ActiveSupport.on_load(:active_record) do
  extend ActsAsTaggableOn::Compatibility
  extend ActsAsTaggableOn::Taggable
  include ActsAsTaggableOn::Tagger
end
ActiveSupport.on_load(:action_view) do
  include ActsAsTaggableOn::TagsHelper
end

