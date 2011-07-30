require "active_record"
require "active_record/version"
require "action_view"
RAILS_3 = ::ActiveRecord::VERSION::MAJOR >= 3

$LOAD_PATH.unshift(File.dirname(__FILE__))

require "acts_as_taggable_on/compatibility/active_record_backports" unless RAILS_3

require "acts_as_taggable_on/utils"

require "acts_as_taggable_on/acts_as_taggable_on"
require "acts_as_taggable_on/acts_as_taggable_on/core"
require "acts_as_taggable_on/acts_as_taggable_on/collection"
require "acts_as_taggable_on/acts_as_taggable_on/cache"
require "acts_as_taggable_on/acts_as_taggable_on/ownership"
require "acts_as_taggable_on/acts_as_taggable_on/related"

#require "acts_as_taggable_on/utils"
require "acts_as_taggable_on/acts_as_tagger"
require "acts_as_taggable_on/tag"
require "acts_as_taggable_on/tag_list"
require "acts_as_taggable_on/tags_helper"
require "acts_as_taggable_on/tagging"

$LOAD_PATH.shift


if defined?(ActiveRecord::Base)
  ActiveRecord::Base.extend ActsAsTaggableOn::Taggable
  ActiveRecord::Base.send :include, ActsAsTaggableOn::Tagger
end

if defined?(ActionView::Base)
  ActionView::Base.send :include, ActsAsTaggableOn::TagsHelper
end