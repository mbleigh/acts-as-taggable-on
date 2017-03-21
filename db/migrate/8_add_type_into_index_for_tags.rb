class AddTypeIntoIndexForTags < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    remove_index :tags, :name if index_exists?(:tags, :name)
    add_index :tags, [:name, :type], unique: true, algorithm: :concurrently unless index_exists?(:tags, [:name, :type])
  end

  def down
    remove_index :tags, [:name, :type] if index_exists?(:tags, [:name, :type])
    add_index :tags, :name, unique: true, algorithm: :concurrently unless index_exists?(:tags, :name)
  end
end
