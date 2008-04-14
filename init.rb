require 'active_record/acts/taggable_on'
# Include hook code here
ActiveRecord::Base.send :include, ActiveRecord::Acts::TaggableOn