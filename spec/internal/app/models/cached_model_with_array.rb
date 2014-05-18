if using_postgresql?
  class CachedModelWithArray < ActiveRecord::Base
    acts_as_taggable
  end
end
