class ParanoidTaggableModel < ActiveRecord::Base
  self.table_name = 'taggable_models'

  def self.paranoid?
    true
  end

  acts_as_taggable
end
