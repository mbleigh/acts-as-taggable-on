class NonStandardIdTaggableNamespacedModel < ActiveRecord::Base
  self.primary_key = 'an_id'
  acts_as_taggable namespace: :nspaced
  acts_as_taggable_on :languages, namespace: :nspaced
  acts_as_taggable_on :skills, namespace: :nspaced
  acts_as_taggable_on :needs, :offerings, namespace: :nspaced
  has_many :untaggable_namespaced_models
end
