class AlteredInheritingTaggableNamespacedModel < TaggableNamespacedModel
  acts_as_taggable_on :parts, namespace: :nspaced
end
