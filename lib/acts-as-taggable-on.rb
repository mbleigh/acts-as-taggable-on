require "active_record"
require "action_view"

$LOAD_PATH.unshift(File.dirname(__FILE__))

require "acts_as_taggable_on/compatibility/active_record_backports" if ActiveRecord::VERSION::MAJOR < 3

require "acts_as_taggable_on/taggable"
require "acts_as_taggable_on/taggable/core"
require "acts_as_taggable_on/taggable/collection"
require "acts_as_taggable_on/taggable/cache"
require "acts_as_taggable_on/taggable/ownership"
require "acts_as_taggable_on/taggable/related"

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
