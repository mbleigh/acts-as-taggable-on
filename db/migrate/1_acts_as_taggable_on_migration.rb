class ActsAsTaggableOnMigration < ActiveRecord::Migration
  def self.up
    ActsAsTaggableOn::Migrator.make_tables!
  end

  def self.down
    ActsAsTaggableOn::Migrator.destroy_tables!
  end
end
