class AddUsersToActsAsTaggableOnMigration < ActiveRecord::Migration
  def self.up
    add_column :taggings, :tagger_id, :integer
    add_column :taggings, :tagger_type, :string
  end
  
  def self.down
    remove_column :taggings, :tagger_type
    remove_column :taggings, :tagger_id
  end
end
