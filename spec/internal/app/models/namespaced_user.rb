class NamespacedUser < ActiveRecord::Base
  acts_as_tagger namespace: :nspaced
end