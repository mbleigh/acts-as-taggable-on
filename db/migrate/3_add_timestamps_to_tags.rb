class AddTimestampToTags < ActiveRecord::Migration
  def up
    add_column :tags, :updated_at, :datetime
    add_column :tags, :aggregated_at, :datetime
  end

  def down
    remove_column :tags, :updated_at
    remove_column :tags, :aggregated_at
  end
end
