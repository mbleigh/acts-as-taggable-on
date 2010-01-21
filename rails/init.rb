require 'acts-as-taggable-on'

ActiveRecord::Base.send :include, ActiveRecord::Acts::TaggableOn
ActiveRecord::Base.send :include, ActiveRecord::Acts::Tagger
ActionView::Base.send :include, TagsHelper if defined?(ActionView::Base)