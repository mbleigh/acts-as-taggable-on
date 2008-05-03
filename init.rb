require 'active_record/acts/taggable_on'
require 'tag'
require 'tag_list'
require 'tags_helper'
require 'tagging'
# Include hook code here
ActiveRecord::Base.send :include, ActiveRecord::Acts::TaggableOn