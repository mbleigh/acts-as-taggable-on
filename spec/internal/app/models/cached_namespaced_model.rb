class CachedNamespacedModel < ActiveRecord::Base
  acts_as_taggable namespace: :nspaced
end
