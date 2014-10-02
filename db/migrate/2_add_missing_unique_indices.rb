class AddMissingUniqueIndices < ActiveRecord::Migration
  def self.up(namespace: nil)
    ActsAsTaggableOn::Migrator.make_unique_indexes! namespace: namespace
  end

  def self.down(namespace: nil)
    ActsAsTaggableOn::Migrator.destroy_unique_indexes! namespace: namespace
  end
end
