class AddMissingUniqueIndices < ActiveRecord::Migration
  def self.up(options = {namespace: nil})
    ActsAsTaggableOn::Migrator.make_unique_indexes! options
  end

  def self.down(options = {namespace: nil})
    ActsAsTaggableOn::Migrator.destroy_unique_indexes! options
  end
end
