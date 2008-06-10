require 'acts-as-taggable-on'

ActiveRecord::Base.send :include, ActiveRecord::Acts::TaggableOn
ActiveRecord::Base.send :include, ActiveRecord::Acts::Tagger

RAILS_DEFAULT_LOGGER.info "** acts_as_taggable_on: initialized properly."