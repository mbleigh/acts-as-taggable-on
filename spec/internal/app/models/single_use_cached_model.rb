# This is used in a spec that expects this model not to have been used before.
class SingleUseCachedModel < ActiveRecord::Base
  self.table_name = 'cached_models'
  acts_as_taggable
end
