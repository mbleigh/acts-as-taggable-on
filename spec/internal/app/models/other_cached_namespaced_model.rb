class OtherCachedNamespacedModel < ActiveRecord::Base
  acts_as_taggable_on :languages, :statuses, :glasses, namespace: :nspaced
end
