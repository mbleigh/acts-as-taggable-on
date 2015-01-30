class OtherTaggableNamespacedModel < ActiveRecord::Base
  acts_as_taggable_on :tags, :languages, namespace: :nspaced
  acts_as_taggable_on :needs, :offerings, namespace: :nspaced
end
