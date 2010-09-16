require "active_record"
require "action_view"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

require "compatibility/active_record_backports" if ActiveRecord::VERSION::MAJOR < 3

require "acts_as_taggable_on"
require "acts_as_taggable_on/core"
require "acts_as_taggable_on/collection"
require "acts_as_taggable_on/cache"
require "acts_as_taggable_on/ownership"
require "acts_as_taggable_on/related"

require "acts_as_tagger"
require "tag"
require "tag_list"
require "tags_helper"
require "tagging"

$LOAD_PATH.shift

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.extend ActsAsTaggableOn::Taggable
  ActiveRecord::Base.send :include, ActsAsTaggableOn::Tagger
end

if defined?(ActionView::Base)
  ActionView::Base.send :include, ActsAsTaggableOn::TagsHelper
end