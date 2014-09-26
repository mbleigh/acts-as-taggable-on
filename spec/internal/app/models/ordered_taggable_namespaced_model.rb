class OrderedTaggableNamespacedModel < ActiveRecord::Base
  acts_as_ordered_taggable namespace: :nspaced
  acts_as_ordered_taggable_on :colours, namespace: :nspaced
end
